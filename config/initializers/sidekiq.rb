Sidekiq.configure_server do |config|
  config.redis = { url: ENV['SIDEKIQ_REDIS_URL'] || 'redis://localhost:6379/2' }
  config.error_handlers << lambda { |exception, ctx|
    Rails.logger.error("❌ Sidekiq Error: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n"))
  }
  config.logger.level = :info
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['SIDEKIQ_REDIS_URL'] || 'redis://localhost:6379/2' }
end
