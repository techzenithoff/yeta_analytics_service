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

class WatchHistory < ApplicationRecord

    # Include shared utils.
    include SharedUtils::Generate

    # Liste des types autorisés
    WATCHABLE_TYPES = %w[Movie Episode].freeze


    before_save :generate_uuid
    
    # Change default params ID to uid
    def to_param
      uid
    end

  #belongs_to :user, foreign_key: :user_id, optional: true  # User dans un autre service
  #belongs_to :watchable, polymorphic: true, optional: true

  #validates :account_id, :watchable_type, :watchable_id, presence: true

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

  # Validation pour s'assurer que la valeur est strictement l'un de ces éléments
    validates :watchable_type, inclusion: { 
        in:  WATCHABLE_TYPES, 
        message: "n'est pas un type de favori valide (doit être l'un de : %{value})" 
    }


end
