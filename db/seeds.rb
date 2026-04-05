# Idempotent seed data for local development.
# Run with: bin/rails db:seed

# ── Tournament ────────────────────────────────────────────────────────────────
tournament = Tournament.find_or_create_by!(sportsdata_id: "58") do |t|
  t.name         = "The Masters Tournament"
  t.status       = "in_progress"
  t.total_rounds = 4
end

# ── Sample Golfers (replace scores with live API data) ────────────────────────
golfers_data = [
  { name: "Scottie Scheffler", sportsdata_id: "40000019", current_score: -9, thru: "F", status: "active", rounds_played: 2, position: 1 },
  { name: "Rory McIlroy",      sportsdata_id: "40000021", current_score: -7, thru: "F", status: "active", rounds_played: 2, position: 2 },
  { name: "Ludvig Åberg",      sportsdata_id: "40000099", current_score: -6, thru: "F", status: "active", rounds_played: 2, position: 3 },
  { name: "Collin Morikawa",   sportsdata_id: "40000088", current_score: -5, thru: "12", status: "active", rounds_played: 1, position: 4 },
  { name: "Xander Schauffele", sportsdata_id: "40000055", current_score: -4, thru: "F", status: "active", rounds_played: 2, position: 5 },
  { name: "Jon Rahm",          sportsdata_id: "40000033", current_score: -3, thru: "F", status: "active", rounds_played: 2, position: 6 },
  { name: "Brooks Koepka",     sportsdata_id: "40000044", current_score: -2, thru: "F", status: "active", rounds_played: 2, position: 7 },
  { name: "Dustin Johnson",    sportsdata_id: "40000066", current_score:  1, thru: "F", status: "cut",    rounds_played: 2, position: nil },
  { name: "Tiger Woods",       sportsdata_id: "40000011", current_score:  4, thru: "F", status: "wd",     rounds_played: 1, position: nil },
  { name: "Phil Mickelson",    sportsdata_id: "40000022", current_score:  6, thru: "F", status: "cut",    rounds_played: 2, position: nil },
]

golfers_data.each do |attrs|
  Golfer.find_or_create_by!(tournament: tournament, sportsdata_id: attrs[:sportsdata_id]) do |g|
    g.assign_attributes(attrs.except(:sportsdata_id))
  end
end

# ── Participants ──────────────────────────────────────────────────────────────
participant_names = ["Alice Chen", "Bob Martinez", "Carol White", "Dave Nguyen", "Eve Thompson"]

participants = participant_names.map do |name|
  Participant.find_or_create_by!(email: "#{name.downcase.gsub(' ', '.')}@example.com") do |p|
    p.name = name
  end
end

# ── Pool ──────────────────────────────────────────────────────────────────────
pool = Pool.find_or_create_by!(name: "Office Masters Pool", tournament: tournament) do |p|
  p.draft_status       = "drafting"
  p.current_pick_number = 1
end

# ── Teams ─────────────────────────────────────────────────────────────────────
participants.each_with_index do |participant, idx|
  Team.find_or_create_by!(pool: pool, participant: participant) do |t|
    t.name        = "#{participant.name.split.first}'s Team"
    t.draft_order = idx + 1
  end
end

puts "Seeded: #{Tournament.count} tournament(s), #{Golfer.count} golfers, " \
     "#{Pool.count} pool(s), #{Team.count} teams, #{Participant.count} participants."
puts "Visit: http://localhost:3000/pools/#{pool.id}/dashboard"
