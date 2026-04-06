class AddRulesTopools < ActiveRecord::Migration[8.0]
  def change
    add_column :pools, :golfers_per_team, :integer, default: 5, null: false
    add_column :pools, :cut_penalty,      :integer, default: 4, null: false
  end
end
