# == Schema Information
#
# Table name: participants
#
#  id         :bigint           not null, primary key
#  email      :string           not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_participants_on_email  (email) UNIQUE
#
class Participant < ApplicationRecord
  has_many :teams, dependent: :destroy
  has_many :pools, through: :teams

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
end
