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

require 'rails_helper'

RSpec.describe Rating, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
