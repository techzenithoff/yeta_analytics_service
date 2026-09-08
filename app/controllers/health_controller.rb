class HealthController < ApplicationController
  #skip_before_action :authenticate_user!

  def check
    render json: {
      status: 'ok',
      service: 'analytics-service',
      version: '1.0.0',
      timestamp: Time.current.iso8601,
      dependencies: check_dependencies
    }, status: :ok
  end

  private

  def check_dependencies
    {
      redis: check_redis,
      database: check_database
    }
  end

  def check_redis
    $redis.ping == 'PONG' ? 'connected' : 'disconnected'
  rescue
    'disconnected'
  end

  def check_database
    ActiveRecord::Base.connection.execute('SELECT 1')
    'connected'
  rescue
    'disconnected'
  end
end
