class WatchHistory < ApplicationRecord

   # Include shared utils.
    include SharedUtils::Generate

    before_save :generate_random_number_uid
    
    # Change default params ID to uid
    def to_param
      uid
    end

  #belongs_to :user, foreign_key: :user_id, optional: true  # User dans un autre service
  #belongs_to :watchable, polymorphic: true, optional: true

  validates :account_id, :watchable_type, :watchable_id, presence: true

  def progress_percent
    return 0 if duration_seconds.blank? || duration_seconds.zero?
    ((position_seconds.to_f / duration_seconds) * 100).round(1)
  end

  def update_position!(new_position)
    update!(
      position_seconds: new_position,
      last_watched_at: Time.current,
      completed: new_position >= (duration_seconds || 0)
    )
  end
end
