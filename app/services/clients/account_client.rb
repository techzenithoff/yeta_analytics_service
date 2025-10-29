# app/services/clients/account_client.rb
class AccountClient < BaseClient
    include HTTParty

   base_uri  "http://localhost:3001/api/v1"

  def self.fetch_accounts(ids, token = nil)

    headers = {}
    headers["Authorization"] = "Bearer #{token}" if token.present?

    result = get_json("/accounts", query: { ids: ids }, headers: headers)



    return [] if result.is_a?(Hash) && result["error"]

    result.is_a?(Hash) ? result["accounts"] : result
  end
end
