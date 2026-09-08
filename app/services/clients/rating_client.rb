module Clients
  class RatingClient < BaseClient
    def self.get_ratings(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/ratings', query: query)
    end

    def self.average_ratings(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/ratings/average', query: query)
    end

    private

    def self.build_query_params(filters)
      {
        content_id: filters[:content_id],
        content_type: filters[:content_type],
        start_date: filters[:start_date],
        end_date: filters[:end_date],
        page: filters[:page] || 1,
        per_page: filters[:per_page] || 100,
      }.compact
    end
  end
end
