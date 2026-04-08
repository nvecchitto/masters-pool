# == Schema Information
#
# Table name: pools
#
#  id                  :bigint           not null, primary key
#  current_pick_number :integer          default(1), not null
#  cut_penalty         :integer          default(4), not null
#  draft_status        :string           default("predraft"), not null
#  golfers_per_team    :integer          default(5), not null
#  max_participants    :integer
#  name                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  creator_id          :integer
#  tournament_id       :bigint           not null
#
# Indexes
#
#  index_pools_on_name           (name) UNIQUE
#  index_pools_on_tournament_id  (tournament_id)
#
# Foreign Keys
#
#  fk_rails_...  (tournament_id => tournaments.id)
#
class Pool < ApplicationRecord
  belongs_to :tournament
  belongs_to :creator, class_name: "Participant", optional: true
  has_many :teams, -> { order(:draft_order) }, dependent: :destroy
  has_many :participants, through: :teams

  validates :name, presence: true, uniqueness: true
  validates :draft_status, inclusion: { in: %w[predraft drafting complete] }
  validates :max_participants, numericality: { greater_than: 1 }, allow_nil: true
  validates :golfers_per_team, numericality: { greater_than: 0 }
  validates :cut_penalty, numericality: { greater_than_or_equal_to: 0 }

  def full?
    max_participants.present? && teams.size >= max_participants
  end

  def joinable?
    draft_status == "predraft" && !full?
  end

  def member?(participant)
    participants.include?(participant)
  end

  # Returns the Team whose turn it is to pick, or nil if draft is over.
  def current_draft_team
    return nil unless draft_status == "drafting"

    ordered_teams = teams.sort_by(&:draft_order)
    n = ordered_teams.size
    total_picks = n * golfers_per_team
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
    total_picks = n * golfers_per_team
    if current_pick_number >= total_picks
      update!(draft_status: "complete")
    else
      increment!(:current_pick_number)
    end
  end

  def draft_complete? = draft_status == "complete"

  # Auto-draft for every consecutive offline participant starting from the
  # current pick. Stops when an online participant is up or the draft ends.
  # "Online" = made a request within the last 2 minutes.
  def auto_draft_while_offline!
    reload
    loop do
      team = current_draft_team
      break if team.nil?
      participant = team.participant.reload
      break if participant.last_active_at.present? &&
               participant.last_active_at > 2.minutes.ago

      best = best_available_golfer
      break if best.nil?

      TeamGolfer.create!(
        team:        team,
        golfer:      best,
        pick_number: current_pick_number
      )
      advance_pick!
    end
  end

  private

  def best_available_golfer
    Golfer.where(tournament: tournament)
          .where.not(id: drafted_golfer_ids)
          .order(Arel.sql("odds_to_win ASC NULLS LAST, position ASC NULLS LAST"))
          .first
  end
end
