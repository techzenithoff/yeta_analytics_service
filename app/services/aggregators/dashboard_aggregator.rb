module Aggregators
  class DashboardAggregator < BaseAggregator
    def get_dashboard_preview
      with_cache(1800) do # 30 minutes cache
        {
          kpis: get_kpis_preview,
          charts: get_charts_preview,
          recent_activity: get_recent_activity,
          quick_stats: get_quick_stats,
        }
      end
    end

    private

    def get_kpis_preview
      handle_errors do
        {
          total_customers: Clients::UserClient.count_users(@filters)&.dig('count') || 0,
          total_content: total_content,
          avg_engagement: get_avg_engagement,
          watch_hours_today: get_watch_hours_today,
        }
      end
    end

    def get_charts_preview
      handle_errors do
        {
          top_movies: Clients::WatchHistoryClient.most_watched({ content_type: 'movie' }, 5) || [],
          top_series: Clients::WatchHistoryClient.most_watched({ content_type: 'series' }, 5) || [],
          user_growth: Clients::UserClient.new_users_trend(@filters) || [],
        }
      end
    end

    def get_recent_activity
      handle_errors do
        {
          recent_watches: Clients::WatchHistoryClient.get_statistics(@filters) || {},
        }
      end
    end

    def get_quick_stats
      handle_errors do
        {
          active_profiles: Clients::ProfileClient.count_profiles(@filters)&.dig('count') || 0,
          total_favorites: Clients::FavoriteClient.count_favorites(@filters)&.dig('count') || 0,
        }
      end
    end

    def total_content
      movies = Clients::MediaClient.count_movies(@filters)&.dig('count') || 0
      series = Clients::MediaClient.count_series(@filters)&.dig('count') || 0
      movies + series
    end

    def get_avg_engagement
      stats = Clients::WatchHistoryClient.get_statistics(@filters) || {}
      (stats.dig('engagement_rate') || 0.0).round(2)
    end

    def get_watch_hours_today
      breakdown = Clients::WatchHistoryClient.watch_time_breakdown(@filters) || {}
      (breakdown.dig('today_hours') || 0.0).round(2)
    end
  end
end
