class CreateTeamGolfers < ActiveRecord::Migration[8.0]
  def change
    create_table :team_golfers do |t|
      t.references :team, null: false, foreign_key: true
      t.references :golfer, null: false, foreign_key: true
      # Which overall pick number this was (for display/history)
      t.integer :pick_number, null: false
      t.timestamps
    end
    # A golfer can only be on one team per pool (enforced via pool membership)
    add_index :team_golfers, %i[team_id golfer_id], unique: true
  end
end
