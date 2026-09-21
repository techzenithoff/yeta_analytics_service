class WatchHistorySerializer < ActiveModel::Serializer
  attributes :id, :uuid, :account_id, :watchable_type, :watchable_id,
             :started_at, :last_watched_at, :position_seconds,
             :duration_seconds, :completed
end