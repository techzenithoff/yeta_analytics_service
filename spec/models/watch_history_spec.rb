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

require 'rails_helper'

RSpec.describe WatchHistory, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
