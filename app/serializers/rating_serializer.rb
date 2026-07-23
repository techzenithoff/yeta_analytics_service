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

class RatingSerializer < ActiveModel::Serializer
  attributes :id, :uuid
end
