# frozen_string_literal: true

#require 'jwt'

module Authenticate
  class InternalTokenServiceOld
    # --- EXCEPTIONS ---
    class TokenError < StandardError; end
    class InvalidTokenError < TokenError; end
    class ExpiredTokenError < TokenError; end
    class MissingConfigError < TokenError; end
    class UnknownIssuerError < TokenError; end

    # --- CONFIGURATION ---
    ALGORITHM    = 'RS256'
    SERVICE_NAME = ENV.fetch("SERVICE_NAME") { raise MissingConfigError, "SERVICE_NAME manquant" }
    INTERNAL_TOKEN_EXPIRATION = Integer(ENV.fetch("INTERNAL_TOKEN_EXPIRATION") { 60 })
    
    # Ma clé privée pour SIGNER les messages que j'envoie
    PRIVATE_KEY = begin
      raw = ENV.fetch("SERVICE_PRIVATE_KEY", nil)
      OpenSSL::PKey::RSA.new(raw.gsub("\\n", "\n")) if raw
    rescue StandardError
      nil
    end

    class << self
      # ===============================
      # ENCODE (Appels Sortants)
      # ===============================
      def encode(audience:, custom_claims: {})
        raise MissingConfigError, "Clé privée non configurée" unless PRIVATE_KEY

        payload = {
          iss: SERVICE_NAME,
          sub: 'service',
          aud: audience,
          iat: Time.current.to_i,
          #exp: 5.minutes.from_now.to_i,
          exp: default_expiration.to_i,
          jti: "#{SERVICE_NAME}-#{SecureRandom.uuid}"
        }.merge(custom_claims)

        # Avec JWT 3.x, on peut passer l'algorithme directement dans les headers
        JWT.encode(payload, PRIVATE_KEY, ALGORITHM, { typ: 'JWT' })
      end

      # ===============================
      # DECODE (Appels Entrants)
      # ===============================
      def decode(token, expected_audience: SERVICE_NAME)
        raise InvalidTokenError, "Token manquant" if token.blank?

        # 1. Identifier l'émetteur (Peek) sans vérifier la signature
        # JWT 3.x : On utilise JWT.decode avec verify_signature: false
        unverified_payload = JWT.decode(token, nil, false).first.with_indifferent_access
        issuer = unverified_payload[:iss]

        # 2. Récupérer la clé publique correspondante
        pub_key = public_key_for(issuer)

        # 3. Validation complète
        # Note : JWT 3.x recommande de passer les options de vérification explicitement
        decoded_array = JWT.decode(token, pub_key, true, {
          algorithm: ALGORITHM,
          verify_aud: true,
          aud: expected_audience,
          verify_iss: true,
          iss: issuer,
          verify_iat: true,
          leeway: 30 # Tolérance pour décalage horloge
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
      # CATALOGUE DES CLÉS
      # ===============================
      def public_key_for(service_name)
        raise UnknownIssuerError, "Émetteur non identifié dans le token" if service_name.blank?

        raw_key = catalogue[service_name]
        if raw_key.blank?
          raise UnknownIssuerError, "Aucune clé publique pour le service : #{service_name}"
        end

        OpenSSL::PKey::RSA.new(raw_key.gsub("\\n", "\n"))
      rescue OpenSSL::PKey::RSAError
        raise TokenError, "La clé publique pour #{service_name} est mal formatée"
      end

      private

      def catalogue
        # Memoization pour ne pas parser le JSON à chaque requête
        @catalogue ||= begin
          JSON.parse(ENV.fetch("PUBLIC_KEYS_JSON", "{}"))
        rescue JSON::ParserError
          Rails.logger.error "[AUTH] PUBLIC_KEYS_JSON est invalide"
          {}
        end
      end

      def revoked?(jti)
        # Optionnel : Vérifier dans Redis si le JTI est blacklisté
        return false unless defined?(Rails) && Rails.cache
        Rails.cache.exist?("revoked_jti:#{jti}")
      end


      def default_expiration
                INTERNAL_TOKEN_EXPIRATION.minutes.from_now
            end
    end
  end
end