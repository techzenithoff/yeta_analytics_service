module Authenticatable
  extend ActiveSupport::Concern

  included do
    
    attr_reader :current_account_id, :current_role
    
  end

  private

  def authenticate!
    header = request.headers['Authorization']

    unless header.present? && header.start_with?('Bearer ')
      return render json: { error: 'Unauthorized' }, status: :unauthorized
    end

    token = header.split(' ').last

    puts "TOKEN: #{token}"

    begin
      payload = Authenticate::AccessTokenService.decode(token)

    rescue Authenticate::AccessTokenService::ExpiredTokenError
      return render json: {status: 401,  error: 'Token expiré' }, status: :unauthorized

    rescue Authenticate::AccessTokenService::InvalidTokenError
      return render json: {status: 401,  error: 'Token invalide' }, status: :unauthorized
    end

    unless payload && payload["account_id"]
      return render json: {status: 401,  error: 'Unauthorized' }, status: :unauthorized
    end

    @current_account_id = payload["account_id"]
    @current_role = payload["role"]
  end
end