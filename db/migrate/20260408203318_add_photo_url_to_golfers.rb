class AddPhotoUrlToGolfers < ActiveRecord::Migration[8.0]
  def change
    add_column :golfers, :photo_url, :string
  end
end
