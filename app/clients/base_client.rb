# frozen_string_literal: true

class BaseClient
    include HTTParty

    DEFAULT_TIMEOUT = 5
    MAX_RETRIES = 2

    class << self
        def request(method, path, options = {}, retries: MAX_RETRIES)

            headers = build_headers.merge(options[:headers] || {})
            options = options.merge(headers: headers, timeout: options[:timeout] || DEFAULT_TIMEOUT)

            response = execute_with_retry(method, path, options, retries)
            
            #handle_response(response)

            response.parsed_response


        rescue Net::ReadTimeout, Net::OpenTimeout => e
            log_error("Timeout", e)
            error_response(:timeout)
        rescue StandardError => e
            log_error("Exception", e)
            error_response(:exception)
        end




        # ===============================
        # HEADERS
        # ===============================
        def build_headers
            token = fetch_service_token
            {
            "Content-Type" => "application/json",
            "Accept" => "application/json",
            "X-Internal-Service-Token" => token, # Header privilégié
            "X-Source-Service" => ENV['SERVICE_NAME'],
            "X-Request-ID" => request_id
            }
        end

        def request_id
            RequestStore.store[:request_id] || SecureRandom.uuid
        end

        # Le nom du service distant (audience pour le JWT)
        def audience_name
            raise NotImplementedError, "Define audience_name in subclass"
        end

        # GESTION DU TOKEN AVEC CACHE AMÉLIORÉ
        def fetch_service_token
            @token_cache ||= {}
            cache_entry = @token_cache[audience_name]

            # On vérifie si le token existe et s'il est encore valide (marge de 10s)
            if cache_entry && cache_entry[:expires_at] > Time.current + 10
            return cache_entry[:token]
            end

            # Sinon, on génère un nouveau token
            token = Authenticate::InternalTokenService.encode(audience: audience_name)
            
            @token_cache[audience_name] = {
            token: token,
            expires_at: Time.current + 1.minute # Aligné sur la durée de vie du JWT
            }

            @token_cache[audience_name][:token]
        end

        # ===============================
        # RETRY & RESPONSE
        # ===============================
        def execute_with_retry(method, path, options, retries)
            attempts = 0
            begin
            attempts += 1
            send(method, path, options)
            rescue Net::ReadTimeout, Net::OpenTimeout => e
            retry if attempts <= retries
            raise e
            end
        end

        def handle_response_OLD(response)
            response.success? ? response.parsed_response : error_response("http_#{response.code}", response)
        end

 
        def self.handle_response(response)
            parsed = response.parsed_response
            Rails.logger.info "DEBUG CLIENT: Parsed structure: #{parsed.inspect}"
            # Si la réponse est un Hash (notre nouvelle structure d'enveloppe)
            if parsed.is_a?(Hash) && parsed.key?('success')
                SharedUtils::ServiceResponse.new(
                success: parsed['success'], # Le booléen venant du Billing-Service
                code:    response.code,
                body:    parsed['body'],
                error:   parsed['error']
                )
            else
                # Cas d'erreur HTTP brute (ex: 500, 404)
                SharedUtils::ServiceResponse.new(
                success: response.success?,
                code:    response.code,
                body:    parsed,
                error:   response.success? ? nil : "http_error_#{response.code}"
                )
            end
        end



        def log_error(type, error)
            # On utilise ENV['SERVICE_NAME'] (soi-même) et audience_name (la cible)
            Rails.logger.error "[#{ENV['SERVICE_NAME']}] Request to [#{audience_name}] #{type}: #{error.message}"
        end

        #def error_response(type, response = nil)
        #    { error: type, status: response&.code, body: response&.body }
        #end

        def error_response(type, response = nil)
            { 'success' => false, 'error' => type, 'status' => response&.code, 'body' => response&.body }
        end


    end

end