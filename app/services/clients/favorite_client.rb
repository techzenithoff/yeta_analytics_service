module Clients
  class FavoriteClient < BaseClient
    def self.get_favorites(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/favorites', query: query)
    end

    def self.count_favorites(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/favorites/count', query: query)
    end

    def self.most_favorited(filters = {}, limit = 10)
      query = build_query_params(filters).merge(limit: limit)
      safe_get('/api/v1/favorites/most-favorited', query: query)
    end

    private

    def self.build_query_params(filters)
      {
        user_id: filters[:user_id],
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
