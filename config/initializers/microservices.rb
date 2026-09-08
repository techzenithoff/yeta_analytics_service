require 'circuit_breaker'

MICROSERVICES_CONFIG = YAML.load_file(
  Rails.root.join('config/services.yml')
)[Rails.env].deep_symbolize_keys

class MicroservicesConfig
  @@circuit_breakers = {}

  def self.config
    MICROSERVICES_CONFIG
  end

  def self.service(name)
    MICROSERVICES_CONFIG.dig(:services, name.to_sym)
  end

  def self.service_url(name)
    service(name)&.dig(:url) || raise("Service #{name} not configured")
  end

  def self.service_timeout(name)
    service(name)&.dig(:timeout) || 5
  end

  def self.service_retry_count(name)
    service(name)&.dig(:retry_count) || 3
  end

  def self.circuit_breaker(name)
    service_name = name.to_sym
    return @@circuit_breakers[service_name] if @@circuit_breakers[service_name]

    config = service(name)&.dig(:circuit_breaker) || {}
    breaker = CircuitBreaker::CircuitBreaker.new(
      failure_threshold: config[:failure_threshold] || 5,
      timeout: config[:timeout] || 60,
      success_threshold: config[:success_threshold] || 2
    )
    @@circuit_breakers[service_name] = breaker
    breaker
  end

  def self.cache_ttl
    MICROSERVICES_CONFIG.dig(:cache, :ttl) || 3600
  end

  def self.cache_provider
    MICROSERVICES_CONFIG.dig(:cache, :provider) || :redis
  end
end
