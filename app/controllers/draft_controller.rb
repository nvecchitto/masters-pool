class DraftController < ApplicationController
  before_action :set_pool

  def show
    @current_team    = @pool.current_draft_team
    @available       = available_golfers
    @teams           = @pool.teams.includes(:golfers, :participant)
    @drafted_ids     = @pool.drafted_golfer_ids
  end

  # POST /pools/:pool_id/draft/heartbeat
  # Called every 60 s by the draft page JS to signal the user is still present.
  def heartbeat
    current_user&.update_columns(last_active_at: Time.current)
    head :ok
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

    unless current_user && current_user.id == @current_team.participant_id
      redirect_to pool_draft_path(@pool), alert: "It's not your turn to pick."
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

    @pool.auto_draft_while_offline!
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

# Pushes updated partials to every browser subscribed to this pool's draft channel.
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

    Turbo::StreamsChannel.broadcast_replace_to(
      "pool_#{pool.id}_draft",
      target: "draft_board",
      partial: "draft/draft_board",
      locals:  { teams: pool.teams.includes(:participant, golfers: :tournament) }
    )
  end
end
