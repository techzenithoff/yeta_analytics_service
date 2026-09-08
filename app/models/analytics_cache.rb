class AnalyticsCache < ApplicationRecord
  self.table_name = 'analytics_caches'

  scope :not_expired, -> { where('expires_at > ?', Time.current) }
end