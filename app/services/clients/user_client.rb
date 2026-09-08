module Clients
  class UserClient < BaseClient
    def self.get_users(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/users', query: query)
    end

    def self.count_users(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/users/count', query: query)
    end

    def self.users_by_country(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/users/by-country', query: query)
    end

    def self.users_by_gender(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/users/by-gender', query: query)
    end

    def self.users_by_age_range(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/users/by-age-range', query: query)
    end

    def self.demographics(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/users/demographics', query: query)
    end

    def self.new_users_trend(filters = {})
      query = build_query_params(filters)
      safe_get('/api/v1/users/trend', query: query)
    end

    private

    def self.build_query_params(filters)
      {
        country: filters[:country],
        gender: filters[:gender],
        age_min: filters[:age_min],
        age_max: filters[:age_max],
        start_date: filters[:start_date],
        end_date: filters[:end_date],
        page: filters[:page] || 1,
        per_page: filters[:per_page] || 100,
      }.compact
    end
  end
end
