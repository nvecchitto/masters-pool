# == Schema Information
#
# Table name: tournaments
#
#  id            :bigint           not null, primary key
#  name          :string           not null
#  status        :string           default("upcoming"), not null
#  total_rounds  :integer          default(4), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  sportsdata_id :string           not null
#
# Indexes
#
#  index_tournaments_on_sportsdata_id  (sportsdata_id) UNIQUE
#
class Tournament < ApplicationRecord
  has_many :golfers, dependent: :destroy
  has_many :pools, dependent: :destroy

  validates :name, presence: true
  validates :sportsdata_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[upcoming in_progress complete] }
  validates :total_rounds, numericality: { greater_than: 0 }

  def in_progress? = status == "in_progress"
  def complete?    = status == "complete"
end
