# == Schema Information
#
# Table name: golfers
#
#  id            :bigint           not null, primary key
#  current_score :integer          default(0), not null
#  name          :string           not null
#  odds_to_win   :decimal(8, 2)
#  position      :integer
#  rounds_played :integer          default(0), not null
#  status        :string           default("active"), not null
#  thru          :string           default("-")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  sportsdata_id :string           not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_golfers_on_tournament_id                    (tournament_id)
#  index_golfers_on_tournament_id_and_sportsdata_id  (tournament_id,sportsdata_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (tournament_id => tournaments.id)
#
class Golfer < ApplicationRecord
  belongs_to :tournament
  has_many :team_golfers, dependent: :destroy
  has_many :teams, through: :team_golfers

  validates :name, presence: true
  validates :sportsdata_id, presence: true, uniqueness: { scope: :tournament_id }
  validates :status, inclusion: { in: %w[active cut wd dq] }

  scope :active,      -> { where(status: "active") }
  # Pre-tournament: sort by odds ascending (favorites first). During tournament: by position.
  scope :by_position, -> { order(Arel.sql("position ASC NULLS LAST, odds_to_win ASC NULLS LAST, current_score ASC")) }

  # Returns the effective score used in pool standings.
  # Cut/WD golfers are penalized +cut_penalty per round they did not play.
  def pool_score(cut_penalty: 4)
    if cut_or_withdrawn?
      remaining = tournament.total_rounds - rounds_played
      current_score + (cut_penalty * remaining)
    else
      current_score
    end
  end

  def cut_or_withdrawn? = status.in?(%w[cut wd dq])

  # Human-readable score (E, -5, +3)
  def display_score
    return "E" if current_score.zero?
    current_score.positive? ? "+#{current_score}" : current_score.to_s
  end

  def display_pool_score(cut_penalty: 4)
    s = pool_score(cut_penalty: cut_penalty)
    return "E" if s.zero?
    s.positive? ? "+#{s}" : s.to_s
  end

  # Converts decimal odds (e.g. 12.3) to American format (+1130).
  # Returns nil if odds_to_win is not set.
  def display_odds
    return nil unless odds_to_win&.positive?
    if odds_to_win >= 2
      "+#{((odds_to_win - 1) * 100).round}"
    else
      "-#{(100 / (odds_to_win - 1)).round.abs}"
    end
  end
end
