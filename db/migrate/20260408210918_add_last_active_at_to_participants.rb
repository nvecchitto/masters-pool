class AddLastActiveAtToParticipants < ActiveRecord::Migration[8.0]
  def change
    add_column :participants, :last_active_at, :datetime
  end
end
