class PoolsController < ApplicationController
  before_action :require_login, only: %i[create join start_draft]
  before_action :set_pool,      only: %i[join start_draft]

  def index
    @pools = Pool.includes(:tournament).order(created_at: :desc)
  end

  def create
    tournament = Tournament.find_or_create_by!(sportsdata_id: params[:sportsdata_id]) do |t|
      t.name         = params[:tournament_name]
      t.total_rounds = params[:total_rounds].presence&.to_i || 4
      t.status       = "upcoming"
    end

    pool = Pool.new(
      name:             params[:pool_name],
      tournament:       tournament,
      draft_status:     "predraft",
      max_participants: params[:max_participants].to_i,
      golfers_per_team: params[:golfers_per_team].to_i,
      cut_penalty:      params[:cut_penalty].to_i,
      creator:          current_user
    )

    unless pool.valid?
      return redirect_to root_path, alert: pool.errors.full_messages.to_sentence
    end

    ActiveRecord::Base.transaction do
      pool.save!
      # Auto-add the creator as the first team
      pool.teams.create!(
        participant: current_user,
        name:        "#{current_user.name}'s Team",
        draft_order: 1
      )
    end

    # Fetch the field so golfers are available when draft starts
    begin
      SportsDataService.new.sync_leaderboard(tournament)
    rescue SportsDataService::ApiError, KeyError => e
      Rails.logger.error("[PoolsController] Leaderboard sync failed: #{e.message}")
    end

    redirect_to root_path, notice: "Pool created! Share the link so others can join."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to root_path, alert: e.message
  end

  # POST /pools/:id/join
  def join
    if @pool.draft_status != "predraft"
      return redirect_to root_path, alert: "This pool's draft has already started."
    end

    if @pool.full?
      return redirect_to root_path, alert: "This pool is already full."
    end

    if @pool.member?(current_user)
      return redirect_to root_path, alert: "You've already joined this pool."
    end

    @pool.teams.create!(
      participant: current_user,
      name:        "#{current_user.name}'s Team",
      draft_order: @pool.teams.count + 1
    )

    redirect_to root_path, notice: "You've joined #{@pool.name}!"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to root_path, alert: e.message
  end

  # POST /pools/:id/start_draft
  def start_draft
    unless current_user.id == @pool.creator_id
      return redirect_to root_path, alert: "Only the pool creator can start the draft."
    end

    if @pool.draft_status != "predraft"
      return redirect_to pool_draft_path(@pool), alert: "Draft has already started."
    end

    if @pool.teams.count < 2
      return redirect_to root_path, alert: "You need at least 2 participants to start the draft."
    end

    # Randomize draft order
    teams = @pool.teams.to_a
    positions = (1..teams.size).to_a.shuffle

    ActiveRecord::Base.transaction do
      # Phase 1: move to large temp values to avoid unique constraint conflicts
      teams.each_with_index { |t, i| t.update_column(:draft_order, 1000 + i) }
      # Phase 2: assign shuffled positions
      teams.each_with_index { |t, i| t.update_column(:draft_order, positions[i]) }

      @pool.update!(draft_status: "drafting")
    end

    redirect_to pool_draft_path(@pool), notice: "Draft started! Good luck."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to root_path, alert: e.message
  end

  private

  def set_pool
    @pool = Pool.includes(:teams, :participants).find(params[:id])
  end
end
