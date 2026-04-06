class AddCreatorAndMaxParticipantsToPools < ActiveRecord::Migration[8.0]
  def change
    add_column :pools, :creator_id, :integer
    add_column :pools, :max_participants, :integer
  end
end
