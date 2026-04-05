# == Schema Information
#
# Table name: pools
#
#  id                  :bigint           not null, primary key
#  current_pick_number :integer          default(1), not null
#  draft_status        :string           default("predraft"), not null
#  name                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  tournament_id       :bigint           not null
#
# Indexes
#
#  index_pools_on_tournament_id  (tournament_id)
#
# Foreign Keys
#
#  fk_rails_...  (tournament_id => tournaments.id)
#
class Pool < ApplicationRecord
  belongs_to :tournament
  has_many :teams, -> { order(:draft_order) }, dependent: :destroy
  has_many :participants, through: :teams

  validates :name, presence: true
  validates :draft_status, inclusion: { in: %w[predraft drafting complete] }

  GOLFERS_PER_TEAM = 5

  # Returns the Team whose turn it is to pick, or nil if draft is over.
  def current_draft_team
    return nil unless draft_status == "drafting"

    ordered_teams = teams.to_a
    n = ordered_teams.size
    total_picks = n * GOLFERS_PER_TEAM
    return nil if current_pick_number > total_picks

    pick_index = current_pick_number - 1   # 0-based
    round      = pick_index / n            # 0-based round
    position   = pick_index % n            # position within the round

    # Even rounds go ascending, odd rounds go descending (snake)
    team_index = round.even? ? position : (n - 1 - position)
    ordered_teams[team_index]
  end

  # IDs of every golfer already drafted in this pool.
  def drafted_golfer_ids
    TeamGolfer.joins(:team).where(teams: { pool_id: id }).pluck(:golfer_id)
  end

  # Advance to the next pick. Marks draft complete when all picks are made.
  def advance_pick!
    n = teams.size
    total_picks = n * GOLFERS_PER_TEAM
    if current_pick_number >= total_picks
      update!(draft_status: "complete")
    else
      increment!(:current_pick_number)
    end
  end

  def draft_complete? = draft_status == "complete"
end
