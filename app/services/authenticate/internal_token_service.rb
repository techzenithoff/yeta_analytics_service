# frozen_string_literal: true

module Authenticate
  class InternalTokenService

    class TokenError < StandardError; end
    class InvalidTokenError < TokenError; end
    class ExpiredTokenError < TokenError; end
    class MissingConfigError < TokenError; end
    class UnknownIssuerError < TokenError; end

    ALGORITHM = 'RS256'

    SERVICE_NAME = ENV.fetch("SERVICE_NAME", "subscription-service")
    INTERNAL_TOKEN_EXPIRATION = Integer(ENV.fetch("INTERNAL_TOKEN_EXPIRATION") { 60 })

    # ===============================
    # 🔐 PRIVATE KEY (SIGN)
    # ===============================
    PRIVATE_KEY = begin
      path = ENV.fetch("INTERNAL_PRIVATE_KEY_PATH") do
        raise MissingConfigError, "INTERNAL_PRIVATE_KEY_PATH manquant"
      end

      raise MissingConfigError, "Fichier privé introuvable: #{path}" unless File.exist?(path)

      OpenSSL::PKey::RSA.new(File.read(path))
    rescue => e
      Rails.logger.error("[AUTH] #{e.message}")
      nil
    end

    class << self

      # ===============================
      # ENCODE
      # ===============================
      def encode(audience:, custom_claims: {})
        raise MissingConfigError, "Clé privée non configurée" unless PRIVATE_KEY

        payload = {
          iss: SERVICE_NAME,
          sub: 'service',
          aud: audience,
          iat: Time.current.to_i,
          exp: default_expiration.to_i,
          jti: "#{SERVICE_NAME}-#{SecureRandom.uuid}"
        }.merge(custom_claims)

        JWT.encode(payload, PRIVATE_KEY, ALGORITHM, { typ: 'JWT' })
      end

      # ===============================
      # DECODE
      # ===============================
      def decode(token, expected_audience: SERVICE_NAME)
        raise InvalidTokenError, "Token manquant" if token.blank?

        unverified_payload = JWT.decode(token, nil, false).first.with_indifferent_access
        issuer = unverified_payload[:iss]

        pub_key = public_key_for(issuer)

        decoded_array = JWT.decode(token, pub_key, true, {
          algorithm: ALGORITHM,
          verify_aud: true,
          aud: expected_audience,
          verify_iss: true,
          iss: issuer,
          verify_iat: true,
          leeway: 30
        })

        decoded_array.first.with_indifferent_access

      rescue UnknownIssuerError => e
        raise InvalidTokenError, e.message
      rescue JWT::ExpiredSignature
        raise ExpiredTokenError, "Le token a expiré"
      rescue JWT::DecodeError => e
        raise InvalidTokenError, "Accès refusé : #{e.message}"
      end

      # ===============================
      # 🔓 PUBLIC KEY (FILES)
      # ===============================
      def public_key_for(service_name)
        raise UnknownIssuerError, "Émetteur non identifié" if service_name.blank?

        base_path = ENV.fetch("INTERNAL_PUBLIC_KEYS_DIR") do
          raise MissingConfigError, "INTERNAL_PUBLIC_KEYS_DIR manquant"
        end

        path = File.join(base_path, "#{service_name}.pem")

        raise UnknownIssuerError, "Aucune clé publique pour #{service_name}" unless File.exist?(path)

        OpenSSL::PKey::RSA.new(File.read(path))

      rescue OpenSSL::PKey::RSAError
        raise TokenError, "Clé publique invalide pour #{service_name}"
      end

      private

      def default_expiration
        INTERNAL_TOKEN_EXPIRATION.minutes.from_now
      end

      def revoked?(jti)
        return false unless defined?(Rails) && Rails.cache
        Rails.cache.exist?("revoked_jti:#{jti}")
      end
    end
  end
end