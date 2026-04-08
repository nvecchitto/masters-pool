class AddHoleScoresToGolfers < ActiveRecord::Migration[8.0]
  def change
    add_column :golfers, :hole_scores, :jsonb, default: {}
  end
end
