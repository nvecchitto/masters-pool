class RemovePhotoUrlFromGolfers < ActiveRecord::Migration[8.0]
  def change
    remove_column :golfers, :photo_url, :string
  end
end
