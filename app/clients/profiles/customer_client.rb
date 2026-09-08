# app/clients/profile/customer_client.rb
# frozen_string_literal: true

module Profile
  class CustomerClient < BaseClient
    def self.base_url
      ENV.fetch('PROFILE_SERVICE_INTERNAL_URL', 'http://localhost:3006')
    end

    def self.audience_name
      "profile-service"
    end

    # Récupère les customers par account_ids
    def self.fetch_by_account_ids(account_ids)
      puts "📤 [CustomerClient] Fetching customers for account_ids: #{account_ids}"
      return {} if account_ids.blank?

      # Le BaseClient retourne directement response.body (Array)
      customers = request(:get, '/internal/api/v1/customers', params: { account_ids: account_ids.join(',') })

      puts "✅ [CustomerClient] Customers fetched: #{customers.inspect}"

      return {} unless customers.is_a?(Array)

      # Indexation par account_id pour accès rapide
      customers.index_by { |customer| customer['account_id'] || customer[:account_id] }

    rescue StandardError => e
      Rails.logger.error "[CustomerClient] Failed to fetch customers: #{e.message}"
      puts "❌ [CustomerClient] Error: #{e.message}"
      {}
    end

    # Récupère un customer spécifique (optionnel)
    def self.get(account_id)
      return nil if account_id.blank?
      
      customers = fetch_by_account_ids([account_id])
      customers[account_id]
    end
  end
end