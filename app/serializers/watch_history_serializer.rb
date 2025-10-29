class WatchHistorySerializer < ActiveModel::Serializer
  attributes :id, :uid, :started_at, :last_watched_at, :position_seconds, :duration_seconds, :completed
  has_one :watchable
  has_one :account
end
