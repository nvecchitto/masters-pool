# == Schema Information
#
# Table name: teams
#
#  id             :bigint           not null, primary key
#  draft_order    :integer          not null
#  name           :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  participant_id :bigint           not null
#  pool_id        :bigint           not null
#
# Indexes
#
#  index_teams_on_participant_id           (participant_id)
#  index_teams_on_pool_id                  (pool_id)
#  index_teams_on_pool_id_and_draft_order  (pool_id,draft_order) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (participant_id => participants.id)
#  fk_rails_...  (pool_id => pools.id)
#
class Team < ApplicationRecord
  belongs_to :pool
  belongs_to :participant
  has_many :team_golfers, dependent: :destroy
  has_many :golfers, through: :team_golfers

  validates :name, presence: true
  validates :draft_order, presence: true,
                          numericality: { greater_than: 0 },
                          uniqueness: { scope: :pool_id }

  # Sum of each golfer's pool_score using the pool's cut penalty.
  # Returns a large number when the team has no golfers yet so they sort last.
  def pool_score
    return 999 if golfers.none?

    golfers.sum { |g| g.pool_score(cut_penalty: pool.cut_penalty) }
  end

  # Formatted for display
  def display_pool_score
    s = pool_score
    return "E" if s.zero?
    s.positive? ? "+#{s}" : s.to_s
  end

  # True when this team has fewer than the maximum allowed golfers
  def can_draft? = golfers.size < pool.golfers_per_team

  # Badge color class (Tailwind) — cycles through 8 distinct colors
  BADGE_COLORS = %w[
    bg-blue-500 bg-emerald-500 bg-violet-500 bg-amber-500
    bg-rose-500  bg-cyan-500   bg-fuchsia-500 bg-lime-500
  ].freeze

  def badge_color
    BADGE_COLORS[(draft_order - 1) % BADGE_COLORS.size]
  end
end
