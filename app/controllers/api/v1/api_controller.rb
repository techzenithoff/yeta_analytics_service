module Api::V1
	class ApiController < ApplicationController
		
		before_action :authenticate_account!

		attr_reader :current_account_id
		attr_reader :access_token # For inter services 

		private

		def authenticate_account!

			token = request.headers["Authorization"]&.split(' ')&.last

			header = request.headers['Authorization']
			token = header.split(' ').last if header

			@access_token = token

			payload = TokenVerifierService.decode(token)

			if payload.nil?
				render json: { error: 'Unauthorized' }, status: :unauthorized
			else

				
				@current_account_id = payload["account_id"]

				
			end
		end
	end
end