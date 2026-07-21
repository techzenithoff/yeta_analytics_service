# app/clients/media/media_client.rb
module Media
    class MadiaClient < BaseClient
        base_uri ENV.fetch('MEDIA_SERVICE_URL', 'http://billing-service.internal')

        def self.audience_name
            "media-service"
        end

    

        def self.get_user_purchases(account_id)
            # 1. On effectue la requête
            #response = request(:get, "/internal/purchases/#{account_id}")

            response = request(:get, "/internal/purchases/#{account_id}", { query: { purchasable_type: "TicketType" } })
            
            # 2. SI la requête n'est pas déjà un ServiceResponse, on le transforme ici
            # Votre BaseClient devrait déjà le faire, mais faisons-le manuellement par sécurité
            if response.is_a?(Hash)
                return SharedUtils::ServiceResponse.new(
                    success: response['success'],
                    body:    response['body'],
                    error:   response['error']
                )
            end
            
            response
        end

        

    end
end