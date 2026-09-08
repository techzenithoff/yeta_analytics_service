class AnalyticsSyncJob < ApplicationJob
  queue_as :analytics_sync

  def perform(user_id)
    Rails.logger.info("Starting analytics sync for user ID: #{user_id}")
    aggregator = AnalyticsAggregator.new(user_id)
    metrics = aggregator.fetch_user_metrics
    
    # Cache or store computed analytics in Redis/Valkey or DB
    cache_key = "user_analytics:#{user_id}"
    Redis.current.setex(cache_key, 1.hour.to_s, metrics.to_json)
    
    Rails.logger.info("Successfully synchronized analytics for user ID: #{user_id}")
  rescue => e
    Rails.logger.error("Failed to sync analytics for user ID #{user_id}: #{e.message}")
    raise e
  end
end
