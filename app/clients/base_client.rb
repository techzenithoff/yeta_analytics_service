# frozen_string_literal: true

class BaseClient
  DEFAULT_TIMEOUT = 5
  MAX_RETRIES = 2

  class << self
    def request(method, path, options = {})
      circuit.run(exception: [Faraday::Error, Circuitbox::OpenCircuitError]) do
        response = connection.send(method) do |req|
          req.url path
          req.body = options[:body].to_json if options[:body].present?
          req.params = options[:params] if options[:params].present?

          # Fusion des headers dynamiques et personnalisés par requête
          req.headers.merge!(dynamic_headers.merge(options[:headers] || {}))

          # Surcharges de timeout
          req.options.timeout = options[:timeout] || DEFAULT_TIMEOUT
          req.options.open_timeout = options[:open_timeout] || DEFAULT_TIMEOUT
        end

        handle_response(response)
      end
    rescue Circuitbox::OpenCircuitError => e
      log_error("CircuitOpen", e)
      error_response(:circuit_open)
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
      log_error("Timeout/Connection", e)
      error_response(:timeout)
    rescue StandardError => e
      log_error("Exception", e)
      error_response(:exception)
    end

    private

    # ===============================
    # CONFIGURATION FARADAY (Thread-Safe)
    # ===============================
    def connection
      @connection ||= Faraday.new(url: base_url) do |faraday|
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter Faraday.default_adapter
      end
    end

    def base_url
      raise NotImplementedError, "Define base_url in subclass"
    end

    # ===============================
    # CIRCUIT BREAKER
    # ===============================
    def circuit
      @circuit ||= Circuitbox.circuit(audience_name.to_sym, {
        exceptions: [Faraday::Error, Net::OpenTimeout, Net::ReadTimeout],
        volume_threshold: 5,   # Nombre min de requêtes avant d'évaluer
        sleep_window: 60,      # Temps d'ouverture en secondes (>= time_window)
        error_threshold: 50,   # Pourcentage d'échecs (50%)
        time_window: 60        # Fenêtre glissante en secondes
      })
    end

    # ===============================
    # HEADERS DYNAMIQUES
    # ===============================
    def dynamic_headers
      {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "X-Internal-Service-Token" => fetch_service_token,
        "X-Source-Service" => ENV.fetch('SERVICE_NAME', 'unknown-service'),
        "X-Request-ID" => request_id
      }
    end

    def request_id
      RequestStore.store[:request_id] || SecureRandom.uuid
    end

    def audience_name
      raise NotImplementedError, "Define audience_name in subclass"
    end

    # ===============================
    # GESTION SÉCURISÉE DU CACHE DE TOKEN (Thread-Safe via Mutex)
    # ===============================
    def token_cache
      @token_cache ||= {}
      @mutex ||= Mutex.new
      [@token_cache, @mutex]
    end

    def fetch_service_token
      cache, mutex = token_cache

      mutex.synchronize do
        cache_entry = cache[audience_name]
        if cache_entry && cache_entry[:expires_at] > Time.current + 10
          return cache_entry[:token]
        end

        token = Authenticate::InternalTokenService.encode(audience: audience_name)

        cache[audience_name] = {
          token: token,
          expires_at: Time.current + 1.minute
        }

        cache[audience_name][:token]
      end
    end

    # ===============================
    # RESPONSE HANDLING
    # ===============================
    def handle_response(response)
      if response.success?
        response.body
      else
        error_response("http_#{response.status}", response)
      end
    end

    def log_error(type, error)
      Rails.logger.error "[#{ENV['SERVICE_NAME']}] Request to [#{audience_name}] #{type}: #{error.message}"
    end

    def error_response(type, response = nil)
      { error: type, status: response&.status, body: response&.body }
    end
  end
end