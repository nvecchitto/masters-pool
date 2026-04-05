class PoolsController < ApplicationController
  def index
    @pools = Pool.includes(:tournament).order(created_at: :desc)
  end

  def create
    tournament = Tournament.find_or_create_by!(sportsdata_id: params[:sportsdata_id]) do |t|
      t.name         = params[:tournament_name]
      t.total_rounds = params[:total_rounds].presence&.to_i || 4
      t.status       = "upcoming"
    end

    pool = Pool.new(name: params[:pool_name], tournament: tournament)

    participants_params = Array(params[:participants])
                           .map { |p| { name: p[:name].to_s.strip, email: p[:email].to_s.strip } }
                           .reject { |p| p[:name].blank? }

    if participants_params.empty?
      return redirect_to root_path, alert: "Add at least one participant."
    end

    ActiveRecord::Base.transaction do
      pool.draft_status = "drafting"
      pool.save!

      draft_positions = (1..participants_params.size).to_a.shuffle

      participants_params.each_with_index do |attrs, idx|
        email = attrs[:email].presence || "#{attrs[:name].parameterize}+#{SecureRandom.hex(4)}@pool.local"
        participant = Participant.find_or_create_by!(email: email) do |p|
          p.name = attrs[:name]
        end
        pool.teams.create!(
          participant:  participant,
          name:         "#{attrs[:name]}'s Team",
          draft_order:  draft_positions[idx]
        )
      end
    end

    # Fetch the field from Sportsdata.io so golfers are available immediately.
    # If the API call fails we still land on the draft page — it will show a banner.
    begin
      SportsDataService.new.sync_leaderboard(tournament)
    rescue SportsDataService::ApiError, KeyError => e
      Rails.logger.error("[PoolsController] Leaderboard sync failed: #{e.message}")
    end

    redirect_to pool_draft_path(pool), notice: "Pool created! Draft is open."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to root_path, alert: e.message
  end
end
