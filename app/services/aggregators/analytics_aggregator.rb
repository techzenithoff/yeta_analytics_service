module Aggregators
  class AnalyticsAggregator < BaseAggregator
    def get_all_analytics
      with_cache(1800) do # 30 minutes cache
        {
          kpis: get_kpis,
          customers: get_customers_analytics,
          content: get_content_analytics,
          engagement: get_engagement_analytics,
          trends: get_trending_analytics,
        }
      end
    end

    def get_customers_analytics
      with_cache(3600) do
        handle_errors do
          {
            total: Clients::UserClient.count_users(@filters)&.dig('count') || 0,
            by_country: Clients::UserClient.users_by_country(@filters) || {},
            by_gender: Clients::UserClient.users_by_gender(@filters) || {},
            by_age: Clients::UserClient.users_by_age_range(@filters) || {},
            demographics: Clients::UserClient.demographics(@filters) || {},
            trend: Clients::UserClient.new_users_trend(@filters) || [],
          }
        end
      end
    end

    def get_content_analytics
      with_cache(3600) do
        handle_errors do
          {
            total: total_content,
            movies: Clients::MediaClient.count_movies(@filters)&.dig('count') || 0,
            series: Clients::MediaClient.count_series(@filters)&.dig('count') || 0,
            episodes: Clients::MediaClient.count_episodes(@filters)&.dig('count') || 0,
            by_genre_movies: Clients::MediaClient.movies_by_genre(@filters) || {},
            by_genre_series: Clients::MediaClient.series_by_genre(@filters) || {},
            trend: Clients::MediaClient.new_content_trend(@filters) || [],
          }
        end
      end
    end

    def get_engagement_analytics
      with_cache(1800) do
        handle_errors do
          watch_stats = Clients::WatchHistoryClient.get_statistics(@filters) || {}
          {
            active_users: watch_stats.dig('active_users', 'count') || 0,
            total_watches: watch_stats.dig('total_watches') || 0,
            engagement_rate: (watch_stats.dig('engagement_rate') || 0.0).round(2),
            avg_watch_time: (watch_stats.dig('avg_watch_time') || 0.0).round(2),
            watch_time_breakdown: Clients::WatchHistoryClient.watch_time_breakdown(@filters) || {},
            content_distribution: Clients::WatchHistoryClient.content_distribution(@filters) || {},
            trend: Clients::WatchHistoryClient.get_trend(@filters) || [],
          }
        end
      end
    end

    def get_trending_analytics
      with_cache(1800) do
        handle_errors do
          {
            most_watched: Clients::WatchHistoryClient.most_watched(@filters, 20) || [],
            most_favorited: Clients::FavoriteClient.most_favorited(@filters, 20) || [],
            highest_rated: Clients::RatingClient.average_ratings(@filters) || [],
          }
        end
      end
    end

    private

    def get_kpis
      handle_errors do
        movies = Clients::MediaClient.count_movies(@filters)&.dig('count') || 0
        series = Clients::MediaClient.count_series(@filters)&.dig('count') || 0
        total_content = movies + series

        {
          total_customers: Clients::UserClient.count_users(@filters)&.dig('count') || 0,
          total_movies: movies,
          total_series: series,
          total_content: total_content,
          avg_engagement: (Clients::WatchHistoryClient.get_statistics(@filters)&.dig('engagement_rate') || 0.0).round(2),
          watch_hours_total: (Clients::WatchHistoryClient.watch_time_breakdown(@filters)&.dig('total_hours') || 0.0).round(2),
        }
      end
    end

    def total_content
      movies = Clients::MediaClient.count_movies(@filters)&.dig('count') || 0
      series = Clients::MediaClient.count_series(@filters)&.dig('count') || 0
      movies + series
    end
  end
end
