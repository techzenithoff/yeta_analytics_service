# == Schema Information
#
# Table name: ratings
#
#  id           :bigint           not null, primary key
#  uuid         :uuid             not null
#  ratable_type :string
#  ratable_id   :bigint
#  rating       :integer          default(0)
#  comment      :text
#  account_id   :bigint           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Rating < ApplicationRecord

    # Include shared utils.
    include SharedUtils::Generate

    before_save :generate_uuid
    

    # Association polymorphe native Rails
    belongs_to :ratable, polymorphic: true, optional: true

    validates :account_id, presence: true
    validates :ratable_type, presence: true, inclusion: { in: %w[Movie Series Season Episode Emission] }
    validates :rating, presence: true, inclusion: { in: 1..5 }
    
    validates :account_id, uniqueness: { scope: [:ratable_id, :ratable_type], message: "a déjà noté ce contenu" }

    # Calcule le résumé des notes pour un contenu donné (similaire à votre maquette)
    def self.summary_for(ratable_type, ratable_id, account_id)

        ratings_scope = where(ratable_type: ratable_type, ratable_id: ratable_id)

        my_rating = ratings_scope.where(account_id: account_id)&.take&.rating

        total_reviews = ratings_scope.count

        return { average: 0.0, total_reviews: 0, distribution: { 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0 } } if total_reviews.zero?

        sum_ratings = ratings_scope.sum(:rating)
        average = (sum_ratings.to_f / total_reviews).round(1)

        # Répartition par étoile (1 à 5)
        distribution = { 5 => 0, 4 => 0, 3 => 0, 2 => 0, 1 => 0 }
        ratings_scope.group(:rating).count.each do |stars, count|
            distribution[stars] = count
        end

        {
            my_rating: my_rating,
            average: average,
            total_reviews: total_reviews,
            distribution: distribution
        }
    end



    # Change default params ID to uid
    def to_param
      uuid
    end


end
