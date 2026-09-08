module Clients
  class WatchHistoryClient < BaseClient
    def self.get_statistics(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/watch-history/stats', query: query)
    end

    def self.get_trend(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/watch-history/trend', query: query)
    end

    def self.most_watched(filters = {}, limit = 10)
      query = build_query_params(filters).merge(limit: limit)
      safe_get('/api/v1/watch-history/most-watched', query: query)
    end

    def self.content_distribution(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/watch-history/content-distribution', query: query)
    end

    def self.user_engagement(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/watch-history/engagement', query: query)
    end

    def self.watch_time_breakdown(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/watch-history/watch-time', query: query)
    end

    private

    def self.build_query_params(filters)
      {
        country: filters[:country],
        gender: filters[:gender],
        age_min: filters[:age_min],
        age_max: filters[:age_max],
        content_type: filters[:content_type],
        start_date: filters[:start_date],
        end_date: filters[:end_date],
        page: filters[:page] || 1,
        per_page: filters[:per_page] || 100,
      }.compact
    end
  end
end
