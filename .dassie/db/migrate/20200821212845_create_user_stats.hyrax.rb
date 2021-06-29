class CreateUserStats < ActiveRecord::Migration[5.2]
  def change
    create_table :user_stats do |t|
      t.integer :user_id
      t.datetime :date
      t.integer :file_views
      t.integer :file_downloads

      t.timestamps null: false
    end

    add_column :file_view_stats, :user_id, :integer
    add_column :file_download_stats, :user_id, :integer

    add_index :user_stats, :user_id
    add_index :file_view_stats, :user_id
    add_index :file_download_stats, :user_id
  end
end
