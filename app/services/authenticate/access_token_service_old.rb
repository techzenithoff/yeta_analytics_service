# frozen_string_literal: true

module Authenticate
  class AccessTokenServiceOld
    class TokenError < StandardError; end
    class InvalidTokenError < TokenError; end
    class ExpiredTokenError < TokenError; end

    # Correction du nom ici pour correspondre à la méthode du bas
    INTERNAL_TOKEN_EXPIRATION = Integer(ENV.fetch("INTERNAL_TOKEN_EXPIRATION") { 60 })
    SERVICE_NAME = ENV.fetch("SERVICE_NAME") { raise TokenError, "SERVICE_NAME manquant" }

    ALGORITHM = 'RS256'.freeze

    # Dans Profile-Service, cette clé sera NIL, et c'est normal !
    PRIVATE_KEY = begin
        raw = ENV.fetch("SERVICE_PRIVATE_KEY", nil)
        OpenSSL::PKey::RSA.new(raw.gsub("\\n", "\n")) if raw
    rescue StandardError
        nil
    end

    # L'émetteur attendu reste le user-service
    ISSUER    = 'user-service'.freeze
    #AUDIENCE  = 'service'.freeze 

    class << self
      def encode(payload, exp: default_expiration)
        raise "Clé privée manquante. Seul le User-Service peut générer des tokens." unless PRIVATE_KEY
        # ... reste du code identique ...
      end

      def decode(token)
        raise InvalidTokenError, "Token manquant" if token.blank?

        payload = JWT.decode(token, nil, false).first.with_indifferent_access
        issuer = payload[:iss]

        pub_key = public_key_for(issuer)

        decoded, = JWT.decode(token, pub_key, true, decode_options(issuer))
        decoded.with_indifferent_access
      rescue JWT::ExpiredSignature
        raise ExpiredTokenError, "Le token a expiré"
      rescue JWT::DecodeError => e
        raise InvalidTokenError, "Accès refusé : #{e.message}"
      end

      private

      def public_key_for(issuer)
        @keys_cache ||= {}
        @keys_cache[issuer] ||= begin
          catalogue = JSON.parse(ENV.fetch("PUBLIC_KEYS_JSON", "{}"))
          raw_key = catalogue[issuer]
          raise InvalidTokenError, "Clé publique introuvable pour l'émetteur : #{issuer}" if raw_key.blank?
          OpenSSL::PKey::RSA.new(raw_key.gsub("\\n", "\n"))
        end
      end

      def decode_options(issuer)
        {
          algorithm: ALGORITHM,
          verify_iss: true,
          iss: issuer, # On vérifie que c'est bien user-service qui a signé
          verify_aud: true,
          aud: current_audience,
          leeway: 30
        }
      end

      def default_expiration
        INTERNAL_TOKEN_EXPIRATION.minutes.from_now
      end

      def current_audience
        # On accepte soit le nom du service, soit une valeur générique par défaut
        ENV.fetch("JWT_ACCEPTED_AUDIENCES", "service,#{SERVICE_NAME}").split(',')
        end
    end
  end
end