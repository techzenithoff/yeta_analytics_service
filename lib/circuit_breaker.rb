module CircuitBreaker
  class CircuitBreaker
    STATES = {
      closed: 'closed',
      open: 'open',
      half_open: 'half_open'
    }.freeze

    attr_reader :failure_threshold, :timeout, :success_threshold

    def initialize(failure_threshold: 5, timeout: 60, success_threshold: 2)
      @failure_threshold = failure_threshold
      @timeout = timeout
      @success_threshold = success_threshold
      
      @failure_count = 0
      @success_count = 0
      @state = STATES[:closed]
      @last_failure_time = nil
    end

    def call(&block)
      case @state
      when STATES[:closed]
        execute_closed(&block)
      when STATES[:open]
        execute_open(&block)
      when STATES[:half_open]
        execute_half_open(&block)
      end
    end

    private

    def execute_closed(&block)
      block.call
      @failure_count = 0
    rescue => e
      @failure_count += 1
      @last_failure_time = Time.current
      
      if @failure_count >= @failure_threshold
        @state = STATES[:open]
        Rails.logger.error("⚠️  Circuit Breaker OPENED (#{@failure_count} failures)")
      end
      
      raise e
    end

    def execute_open(&block)
      if Time.current - @last_failure_time >= @timeout
        @state = STATES[:half_open]
        @success_count = 0
        Rails.logger.warn("🔄 Circuit Breaker HALF_OPEN")
        execute_half_open(&block)
      else
        raise CircuitBreakerOpenError, "Circuit breaker is open"
      end
    end

    def execute_half_open(&block)
      block.call
      @success_count += 1
      
      if @success_count >= @success_threshold
        @state = STATES[:closed]
        @failure_count = 0
        Rails.logger.info("✅ Circuit Breaker CLOSED")
      end
    rescue => e
      @failure_count = 1
      @state = STATES[:open]
      @last_failure_time = Time.current
      Rails.logger.error("❌ Circuit Breaker OPENED (half_open failure)")
      raise e
    end
  end

  class CircuitBreakerOpenError < StandardError; end
end
