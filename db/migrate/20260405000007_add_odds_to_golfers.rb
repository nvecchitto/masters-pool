class AddOddsToGolfers < ActiveRecord::Migration[8.0]
  def change
    add_column :golfers, :odds_to_win, :decimal, precision: 8, scale: 2
  end
end
