# app/services/token_verifier.rb
require 'jwt'
require 'openssl'

class RsaTokenVerifierService
  #PUBLIC_KEY = OpenSSL::PKey::RSA.new(File.read(Rails.root.join('config', 'public.pem')))

  def self.decode(token)
    #JWT.decode(token, PUBLIC_KEY, true, { algorithm: 'RS256' })[0]
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end
