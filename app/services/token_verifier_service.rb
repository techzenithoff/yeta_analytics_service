class TokenVerifierService
  #SECRET_KEY = Rails.application.credentials.auth_service[:secret_key] || 'supersecret'

  SECRET_KEY = Rails.application.credentials.dig(:auth_service, :production, :secret_key)

  def self.decode(token)

    #puts "TOKEN: #{token}"
    JWT.decode(token, SECRET_KEY, true, { algorithm: 'HS256' })[0]
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end