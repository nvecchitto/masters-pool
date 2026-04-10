class DashboardController < ApplicationController
  def index
    @pool = Pool.includes(teams: { golfers: :tournament })
                .find(params[:pool_id])

    @tournament    = @pool.tournament
    @teams         = @pool.teams.sort_by(&:pool_score)
    @golfers       = @tournament.golfers.by_position.includes(teams: :pool)
    @drafted_ids   = @pool.drafted_golfer_ids

    # Build a quick lookup: golfer_id → [team, badge_color]
    @golfer_team_map = build_golfer_team_map(@pool)
  end

  # POST /pools/:pool_id/dashboard/heartbeat
  # Called every 2 minutes by the dashboard page to signal a viewer is present.
  # SyncLeaderboardJob skips the API when no heartbeat has been received recently.
  def heartbeat
    Rails.cache.write("dashboard_viewers_present", true, expires_in: 5.minutes)
    head :ok
  end

  def team_scorecard
    @pool = Pool.includes(teams: { golfers: :tournament }).find(params[:pool_id])
    @team = @pool.teams.includes(:participant, golfers: :tournament).find(params[:team_id])
    @tournament = @pool.tournament
    @teams = @pool.teams.sort_by(&:pool_score)
    @golfers = @team.golfers.sort_by { |g| g.pool_score(cut_penalty: @pool.cut_penalty) }
  end

  private

  def build_golfer_team_map(pool)
    pool.teams.each_with_object({}) do |team, map|
      team.golfers.each { |g| map[g.id] = team }
    end
  end
end
