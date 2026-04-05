# == Schema Information
#
# Table name: team_golfers
#
#  id          :bigint           not null, primary key
#  pick_number :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  golfer_id   :bigint           not null
#  team_id     :bigint           not null
#
# Indexes
#
#  index_team_golfers_on_golfer_id              (golfer_id)
#  index_team_golfers_on_team_id                (team_id)
#  index_team_golfers_on_team_id_and_golfer_id  (team_id,golfer_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (golfer_id => golfers.id)
#  fk_rails_...  (team_id => teams.id)
#
class TeamGolfer < ApplicationRecord
  belongs_to :team
  belongs_to :golfer

  validates :pick_number, presence: true, numericality: { greater_than: 0 }
end
