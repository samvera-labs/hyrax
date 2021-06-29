class CreateTrophies < ActiveRecord::Migration[5.2]
  def change
    create_table :trophies do |t|
      t.integer :user_id
      t.string :generic_file_id

      t.timestamps null: false
    end
  end
end
