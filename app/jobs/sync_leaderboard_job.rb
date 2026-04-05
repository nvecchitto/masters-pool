# Syncs golfer scores for every in-progress tournament, then broadcasts
# live Turbo Stream updates to any open dashboard connections.
#
# Schedule this job every ~2 minutes during an active tournament, e.g.:
#   SyncLeaderboardJob.set(wait: 2.minutes).perform_later
# or via a recurring Solid Queue task in config/recurring.yml.
class SyncLeaderboardJob < ApplicationJob
  queue_as :default

  def perform(tournament_id = nil)
    tournaments = if tournament_id
                    Tournament.where(id: tournament_id)
                  else
                    Tournament.where(status: "in_progress")
                  end

    tournaments.each do |tournament|
      SportsDataService.new.sync_leaderboard(tournament)
      broadcast_leaderboard_update(tournament)
    rescue SportsDataService::ApiError => e
      Rails.logger.error("[SyncLeaderboardJob] API error for tournament " \
                         "#{tournament.id}: #{e.message}")
    rescue KeyError => e
      Rails.logger.error("[SyncLeaderboardJob] #{e.message}")
      break  # No key set — don't hammer the API on every retry
    end
  end

  private

  def broadcast_leaderboard_update(tournament)
    tournament.pools.each do |pool|
      # Broadcast updated standings to the dashboard for this pool.
      # The dashboard subscribes via: turbo_stream_from "pool_#{pool.id}_standings"
      Turbo::StreamsChannel.broadcast_replace_to(
        "pool_#{pool.id}_standings",
        target: "standings",
        partial: "dashboard/standings",
        locals: { teams: pool.teams.includes(golfers: :tournament).sort_by(&:pool_score) }
      )

      # Broadcast the updated full leaderboard panel.
      drafted_ids = pool.drafted_golfer_ids
      Turbo::StreamsChannel.broadcast_replace_to(
        "pool_#{pool.id}_leaderboard",
        target: "leaderboard",
        partial: "dashboard/leaderboard",
        locals: {
          golfers:     tournament.golfers.by_position.includes(:teams),
          pool:        pool,
          drafted_ids: drafted_ids
        }
      )
    end
  end
end
