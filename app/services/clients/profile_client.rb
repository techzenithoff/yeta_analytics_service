module Clients
  class ProfileClient < BaseClient
    def self.get_profiles(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/profiles', query: query)
    end

    def self.count_profiles(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/profiles/count', query: query)
    end

    private

    def self.build_query_params(filters)
      {
        user_id: filters[:user_id],
        start_date: filters[:start_date],
        end_date: filters[:end_date],
        page: filters[:page] || 1,
        per_page: filters[:per_page] || 100,
      }.compact
    end
  end
end
