module Clients
  class MediaClient < BaseClient
    def self.count_movies(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/movies/count', query: query)
    end

    def self.count_series(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/series/count', query: query)
    end

    def self.count_episodes(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/episodes/count', query: query)
    end

    def self.movies_by_genre(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/movies/by-genre', query: query)
    end

    def self.series_by_genre(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/series/by-genre', query: query)
    end

    def self.new_content_trend(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/media/trend', query: query)
    end

    private

    def self.build_query_params(filters)
      {
        genre: filters[:genre],
        language: filters[:language],
        start_date: filters[:start_date],
        end_date: filters[:end_date],
        page: filters[:page] || 1,
        per_page: filters[:per_page] || 100,
      }.compact
    end
  end
end
