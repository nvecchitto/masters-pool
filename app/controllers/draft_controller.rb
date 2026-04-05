class DraftController < ApplicationController
  before_action :set_pool

  def show
    @current_team    = @pool.current_draft_team
    @available       = available_golfers
    @teams           = @pool.teams.includes(:golfers, :participant)
    @drafted_ids     = @pool.drafted_golfer_ids
  end

  # POST /pools/:pool_id/draft/sync
  def sync
    begin
      SportsDataService.new.sync_leaderboard(@pool.tournament)
      redirect_to pool_draft_path(@pool), notice: "Field synced successfully."
    rescue SportsDataService::ApiError, KeyError => e
      redirect_to pool_draft_path(@pool), alert: "Sync failed: #{e.message}"
    end
  end

  # POST /pools/:pool_id/draft/pick
  def pick
    @current_team = @pool.current_draft_team

    if @current_team.nil?
      redirect_to pool_draft_path(@pool), alert: "The draft is already complete."
      return
    end

    golfer = Golfer.find_by(id: params[:golfer_id],
                             tournament: @pool.tournament)

    if golfer.nil? || @pool.drafted_golfer_ids.include?(golfer.id)
      redirect_to pool_draft_path(@pool), alert: "That golfer is not available."
      return
    end

    TeamGolfer.create!(
      team:        @current_team,
      golfer:      golfer,
      pick_number: @pool.current_pick_number
    )
    @pool.advance_pick!

    broadcast_draft_update(@pool)

    redirect_to pool_draft_path(@pool)
  end

  private

  def set_pool
    @pool = Pool.includes(teams: { golfers: :tournament }).find(params[:pool_id])
  end

  def available_golfers
    Golfer.where(tournament: @pool.tournament)
          .where.not(id: @pool.drafted_golfer_ids)
          .by_position
  end

  # Pushes the updated "current picker" and "available golfers" partials to
  # every browser tab subscribed to this pool's draft channel.
  def broadcast_draft_update(pool)
    next_team = pool.current_draft_team

    Turbo::StreamsChannel.broadcast_replace_to(
      "pool_#{pool.id}_draft",
      target: "current_picker",
      partial: "draft/current_picker",
      locals:  { pool: pool, current_team: next_team }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      "pool_#{pool.id}_draft",
      target: "available_golfers",
      partial: "draft/available_golfers",
      locals:  { pool: pool, golfers: available_golfers }
    )
  end
end
