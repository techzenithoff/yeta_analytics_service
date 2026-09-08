require 'faraday'
require 'faraday_middleware'
require 'circuit_breaker'

module Clients
  class BaseClient
    class ServiceUnavailableError < StandardError; end
    class TimeoutError < StandardError; end
    class BadRequestError < StandardError; end
    class CircuitBreakerOpenError < StandardError; end

    def self.inherited(child)
      super
      service_name = child.name.demodulize.underscore.gsub('_client', '')
      @service_name = service_name
    end

    def self.service_name
      @service_name
    end

    protected

    def self.create_connection
      service_url = MicroservicesConfig.service_url(service_name)
      timeout = MicroservicesConfig.service_timeout(service_name)

      Faraday.new(
        url: service_url,
        request: { timeout: timeout }
      ) do |conn|
        conn.request :json
        conn.response :json
        conn.adapter :net_http
      end
    end

    def self.safe_get(path, options = {})
      handle_request { get(path, options) }
    end

    def self.safe_post(path, options = {})
      handle_request { post(path, options) }
    end

    def self.safe_put(path, options = {})
      handle_request { put(path, options) }
    end

    def self.safe_delete(path, options = {})
      handle_request { delete(path, options) }
    end

    def self.get(path, options = {})
      execute_request(:get, path, options)
    end

    def self.post(path, options = {})
      execute_request(:post, path, options)
    end

    def self.put(path, options = {})
      execute_request(:put, path, options)
    end

    def self.delete(path, options = {})
      execute_request(:delete, path, options)
    end

    private

    def self.execute_request(method, path, options)
      circuit_breaker = MicroservicesConfig.circuit_breaker(service_name)
      retry_count = MicroservicesConfig.service_retry_count(service_name)

      circuit_breaker.call do
        attempt_request(method, path, options, retry_count)
      end
    rescue CircuitBreaker::CircuitBreakerOpenError => e
      Rails.logger.error("🔴 Circuit Breaker Open for #{service_name}: #{e.message}")
      raise CircuitBreakerOpenError, "Service #{service_name} is temporarily unavailable"
    end

    def self.attempt_request(method, path, options, retry_count, attempt = 1)
      conn = create_connection
      
      response = case method
                 when :get
                   conn.get(path, options[:query])
                 when :post
                   conn.post(path, options[:body])
                 when :put
                   conn.put(path, options[:body])
                 when :delete
                   conn.delete(path)
                 end

      handle_response(response)
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
      if attempt <= retry_count
        wait_time = 2 ** attempt
        Rails.logger.warn("⏱️  Timeout for #{service_name} (Retry #{attempt}/#{retry_count}). Waiting #{wait_time}s...")
        sleep(wait_time)
        attempt_request(method, path, options, retry_count, attempt + 1)
      else
        Rails.logger.error("❌ Service #{service_name} timeout after #{retry_count} retries")
        raise TimeoutError, "Service #{service_name} timeout"
      end
    rescue StandardError => e
      Rails.logger.error("❌ Request failed for #{service_name}: #{e.class} - #{e.message}")
      raise e
    end

    def self.handle_response(response)
      case response.status
      when 200..299
        response.body
      when 400..499
        Rails.logger.error("❌ Client Error (#{response.status}): #{response.body}")
        raise BadRequestError, "Bad request: #{response.body}"
      when 500..599
        Rails.logger.error("❌ Server Error (#{response.status}): #{response.body}")
        raise ServiceUnavailableError, "Service unavailable"
      else
        Rails.logger.warn("⚠️  Unexpected status (#{response.status})")
        nil
      end
    end
  end
end
