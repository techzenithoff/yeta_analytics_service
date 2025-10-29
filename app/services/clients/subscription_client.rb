
class SubscriptionClient < BaseClient
    include HTTParty

   base_uri  "http://localhost:3002/api/v1"

  def self.fetch_subscriptions(ids, token = nil)

    headers = {}
    headers["Authorization"] = "Bearer #{token}" if token.present?

    result = get_json("/subscriptions", query: { ids: ids }, headers: headers)



    return [] if result.is_a?(Hash) && result["error"]

    result.is_a?(Hash) ? result["subscriptions"] : result
  end
end
