class AddPasswordDigestToParticipants < ActiveRecord::Migration[8.0]
  def change
    add_column :participants, :password_digest, :string
  end
end
