module Aggregators
  class BaseAggregator
    def initialize(filters = {})
      @filters = filters
    end

    protected

    def with_cache(ttl)
      cache_key = "analytics:#{self.class.name}:#{@filters.sort.to_s}"
      
      cached = $redis.get(cache_key)
      return JSON.parse(cached) if cached

      result = yield
      $redis.setex(cache_key, ttl, result.to_json)
      result
    end

    def handle_errors(&block)
      begin
        block.call
      rescue Clients::BaseClient::TimeoutError => e
        Rails.logger.warn("⏱️  Aggregator timeout: #{e.message}")
        {}
      rescue Clients::BaseClient::ServiceUnavailableError => e
        Rails.logger.warn("❌ Service unavailable: #{e.message}")
        {}
      rescue Clients::BaseClient::CircuitBreakerOpenError => e
        Rails.logger.warn("🔴 Circuit breaker open: #{e.message}")
        {}
      rescue => e
        Rails.logger.error("❌ Aggregator error: #{e.message}")
        {}
      end
    end
  end
end
