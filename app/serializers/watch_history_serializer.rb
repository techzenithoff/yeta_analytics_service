# == Schema Information
#
# Table name: watch_histories
#
#  id               :bigint           not null, primary key
#  uuid             :uuid             not null
#  watchable_type   :string
#  watchable_id     :bigint
#  account_id       :bigint           not null
#  started_at       :datetime
#  last_watched_at  :datetime
#  position_seconds :integer
#  duration_seconds :integer
#  completed        :boolean
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class WatchHistorySerializer < ActiveModel::Serializer
  attributes :id, :uid, :started_at, :last_watched_at, :position_seconds, :duration_seconds, :completed
  #has_one :watchable
  #has_one :account
end
