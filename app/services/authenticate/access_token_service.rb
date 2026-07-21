# frozen_string_literal: true

module Authenticate
  class AccessTokenService
    class TokenError < StandardError; end
    class InvalidTokenError < TokenError; end
    class ExpiredTokenError < TokenError; end
    class MissingConfigError < TokenError; end

    INTERNAL_TOKEN_EXPIRATION = Integer(ENV.fetch("INTERNAL_TOKEN_EXPIRATION") { 60 })
    SERVICE_NAME = ENV.fetch("SERVICE_NAME")

    ALGORITHM = 'RS256'.freeze

    # ===============================
    # 🔐 PRIVATE KEY (fichier)
    # ===============================
    PRIVATE_KEY = begin
      path = ENV.fetch("INTERNAL_PRIVATE_KEY_PATH") do
        raise MissingConfigError, "INTERNAL_PRIVATE_KEY_PATH manquant"
      end

      OpenSSL::PKey::RSA.new(File.read(path))
    rescue StandardError
      nil
    end

    ISSUER = 'user-service'.freeze

    class << self
      # ===============================
      # ENCODE (interne)
      # ===============================
      def encode(payload, exp: default_expiration)
        raise "Clé privée manquante" unless PRIVATE_KEY

        payload = payload.merge(
          iss: SERVICE_NAME,
          aud: current_audience,
          exp: exp.to_i,
          iat: Time.current.to_i,
          jti: "#{SERVICE_NAME}-#{SecureRandom.uuid}"
        )

        JWT.encode(payload, PRIVATE_KEY, ALGORITHM)
      end

      # ===============================
      # DECODE
      # ===============================
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

      # ===============================
      # 🔑 Lecture clé publique depuis fichier
      # ===============================
      def public_key_for(issuer)
        @keys_cache ||= {}

        @keys_cache[issuer] ||= begin
          path = public_key_path_for(issuer)

          raise InvalidTokenError, "Clé publique introuvable pour #{issuer}" unless File.exist?(path)

          OpenSSL::PKey::RSA.new(File.read(path))
        end
      end

      # ===============================
      # 📂 Dossier des clés publiques
      # ===============================
      def public_key_path_for(issuer)
        base_path = ENV.fetch("INTERNAL_PUBLIC_KEYS_DIR") do
          raise MissingConfigError, "INTERNAL_PUBLIC_KEYS_DIR manquant"
        end

        File.join(base_path, "#{issuer}.pem")
      end

      # ===============================
      # OPTIONS JWT
      # ===============================
      def decode_options(issuer)
        {
          algorithm: ALGORITHM,
          verify_iss: true,
          iss: issuer,
          verify_aud: true,
          aud: current_audience,
          leeway: 30
        }
      end

      def default_expiration
        INTERNAL_TOKEN_EXPIRATION.minutes.from_now
      end

      def current_audience
        ENV.fetch("JWT_ACCEPTED_AUDIENCES", "service,#{SERVICE_NAME}").split(',')
      end
    end
  end
end