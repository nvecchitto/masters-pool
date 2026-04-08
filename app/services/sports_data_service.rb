# Fetches leaderboard data from the Sportsdata.io Golf v2 API and syncs
# the local Golfer records for a given Tournament.
#
# API key is read from Rails credentials or ENV:
#   Rails.application.credentials.sportsdata_api_key
#   ENV["SPORTSDATA_API_KEY"]
#
# Sportsdata.io leaderboard endpoint:
#   GET https://api.sportsdata.io/golf/v2/json/Leaderboard/{tournamentId}
#
# IMPORTANT — score calculation:
#   The top-level "TotalScore" field returns a decimal projection value, NOT the
#   actual golf score (e.g. -10.2 when the real score is -17).
#   Actual scores are derived by summing the boolean result fields on each
#   completed hole: Birdie=-1, Eagle=-2, DoubleEagle=-3, Bogey=+1,
#   DoubleBogey=+2, TripleBogey=+3, WorseThanDoubleBogey=+4.
#   The hole-level "ToPar" field is unreliable (shows 0 for over-par holes).
#   Only holes from rounds where IsRoundOver=true (tournament level) are counted.

class SportsDataService
  BASE_URL = "https://api.sportsdata.io/golf/v2/json"

  class ApiError < StandardError; end

  def initialize
    @api_key = Rails.application.credentials.sportsdata_api_key ||
               ENV.fetch("SPORTSDATA_API_KEY") do
                 raise KeyError, "SPORTSDATA_API_KEY is not set"
               end
  end

  # Fetches the leaderboard and upserts Golfer records for +tournament+.
  def sync_leaderboard(tournament)
    body = fetch_leaderboard(tournament.sportsdata_id)
    upsert_golfers(tournament, body)
  end

  # Returns upcoming / in-progress tournaments for the given year, sorted with
  # live tournaments first then by start date.
  def fetch_tournaments(year = Time.current.year)
    response = HTTP.timeout(10)
                   .get("#{BASE_URL}/Tournaments/#{year}",
                        params: { key: @api_key })

    unless response.status.success?
      raise ApiError, "Sportsdata.io returned #{response.status} fetching tournaments for #{year}"
    end

    response.parse(:json)
      .reject { |t| t["Canceled"] || t["IsOver"] }
      .map do |t|
        {
          sportsdata_id:  t["TournamentID"].to_s,
          name:           t["Name"].to_s.strip,
          location:       t["Location"].to_s.strip,
          venue:          t["Venue"].to_s.strip,
          start_date:     t["StartDate"]&.first(10),
          end_date:       t["EndDate"]&.first(10),
          is_in_progress: t["IsInProgress"],
          total_rounds:   t["Rounds"]&.length || 4
        }
      end
      .sort_by { |t| [t[:is_in_progress] ? 0 : 1, t[:start_date].to_s] }
  end

  # Returns the full parsed leaderboard body (keys: "Tournament", "Players").
  def fetch_leaderboard(tournament_sportsdata_id)
    response = HTTP.timeout(10)
                   .get("#{BASE_URL}/Leaderboard/#{tournament_sportsdata_id}",
                        params: { key: @api_key })

    unless response.status.success?
      raise ApiError, "Sportsdata.io returned #{response.status} for " \
                      "tournament #{tournament_sportsdata_id}"
    end

    body = response.parse(:json)

    unless body.key?("Players")
      raise ApiError, "Unexpected response shape — missing 'Players' key. " \
                      "Keys present: #{body.keys.inspect}"
    end

    body
  end

  private

  # Upserts Golfer records from the full leaderboard body.
  # body = { "Tournament" => {...}, "Players" => [...] }
  def upsert_golfers(tournament, body)
    tournament_meta = body["Tournament"] || {}
    is_over         = tournament_meta["IsOver"]

    # Round numbers marked complete at the tournament level.
    completed_rounds = tournament_meta["Rounds"].to_a
                                                .select { |r| r["IsRoundOver"] }
                                                .map    { |r| r["Number"] }
                                                .to_set

    body["Players"].filter_map do |player|
      sportsdata_id = player["PlayerID"].to_s
      next if sportsdata_id.blank?

      golfer = Golfer.find_or_initialize_by(
        tournament: tournament,
        sportsdata_id: sportsdata_id
      )

      # TotalThrough = holes completed in the current round (nil when not playing).
      total_through = player["TotalThrough"].presence&.to_i
      score, rounds_played = score_from_holes(player, completed_rounds, total_through)

      golfer.assign_attributes(
        name:          player["Name"].to_s.strip,
        current_score: score,
        thru:          parse_thru(is_over, completed_rounds, total_through),
        status:        parse_status(player),
        rounds_played: rounds_played,
        position:      player["Rank"].presence&.to_i,
        odds_to_win:   player["OddsToWin"].presence,
        hole_scores:   extract_hole_scores(player)
      )

      golfer.save!
      golfer
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[SportsDataService] Failed to save golfer #{sportsdata_id}: #{e.message}")
      nil
    end
  end

  # Calculates actual score and rounds played from hole-level boolean fields.
  #
  # For completed rounds: all 18 holes are summed.
  # For the current round in progress: only the first `total_through` holes
  #   in play order are summed (respecting BackNineStart).
  #
  # Returns [score, rounds_played].
  #
  # Why booleans and not ToPar: the hole-level ToPar field is unreliable —
  # it shows 0 for over-par holes. The boolean fields (Birdie, Eagle, Bogey…)
  # correctly reflect the actual recorded outcome for each hole.
  def score_from_holes(player, completed_rounds, total_through)
    all_rounds = player["Rounds"].to_a

    # --- Completed rounds ---
    done = all_rounds.select { |r| completed_rounds.include?(r["Number"]) }
    score = done.sum { |r| sum_holes(r["Holes"].to_a) }

    # --- Current round in progress ---
    if total_through&.positive?
      live_round = all_rounds.find { |r| !completed_rounds.include?(r["Number"]) }
      if live_round
        played = holes_in_play_order(live_round).first(total_through)
        score += sum_holes(played)
      end
    end

    [score, done.size]
  end

  # Returns the 18 holes in the order the player actually plays them,
  # accounting for whether they started on the back nine.
  def holes_in_play_order(round)
    by_number = round["Holes"].to_a.index_by { |h| h["Number"] }
    order     = round["BackNineStart"] ? (10..18).to_a + (1..9).to_a : (1..18).to_a
    order.filter_map { |n| by_number[n] }
  end

  # Sums hole-level boolean result fields to get strokes relative to par.
  def sum_holes(holes)
    holes.sum do |hole|
      if    hole["DoubleEagle"]          then -3
      elsif hole["Eagle"]                then -2
      elsif hole["Birdie"]               then -1
      elsif hole["Bogey"]                then +1
      elsif hole["DoubleBogey"]          then +2
      elsif hole["TripleBogey"]          then +3
      elsif hole["WorseThanDoubleBogey"] then +4
      else 0
      end
    end
  end

  # Builds a hash of round_number → { hole_number → outcome_string } for storage.
  # Only holes with a recorded result are included. Outcome strings:
  #   "double_eagle", "eagle", "birdie", "par", "bogey",
  #   "double_bogey", "triple_bogey", "worse"
  def extract_hole_scores(player)
    player["Rounds"].to_a.each_with_object({}) do |round, rounds_hash|
      holes_hash = round["Holes"].to_a.each_with_object({}) do |hole, h|
        type = hole_type(hole)
        h[hole["Number"].to_s] = type if type
      end
      rounds_hash[round["Number"].to_s] = holes_hash unless holes_hash.empty?
    end
  end

  def hole_type(hole)
    if    hole["DoubleEagle"]          then "double_eagle"
    elsif hole["Eagle"]                then "eagle"
    elsif hole["Birdie"]               then "birdie"
    elsif hole["Bogey"]                then "bogey"
    elsif hole["DoubleBogey"]          then "double_bogey"
    elsif hole["TripleBogey"]          then "triple_bogey"
    elsif hole["WorseThanDoubleBogey"] then "worse"
    elsif hole["Par"]                  then "par"
    end
  end

  # Returns the "thru" display string shown in the leaderboard.
  #   "F"     – round or tournament finished
  #   "1"-"17" – current hole mid-round
  #   "-"     – not yet started / pre-tournament
  def parse_thru(is_over, completed_rounds, total_through)
    return "F" if is_over
    return "F" if total_through.nil? && completed_rounds.any?
    return "-" if total_through.nil?
    total_through == 18 ? "F" : total_through.to_s
  end

  # Derives player status from explicit boolean / string fields.
  def parse_status(player)
    return "wd" if player["IsWithdrawn"]

    case player["TournamentStatus"].to_s.downcase.strip
    when "cut"              then "cut"
    when "wd", "withdrawal" then "wd"
    when "dq"               then "dq"
    else                         "active"
    end
  end
end
