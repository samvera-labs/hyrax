class AddWorksToUserStats < ActiveRecord::Migration[5.2]
  def self.up
    add_column :user_stats, :work_views, :integer
    add_column :work_view_stats, :user_id, :integer
    add_index :work_view_stats, :user_id
  end

  def self.down
    remove_column :user_stats, :work_views, :integer
    remove_column :work_view_stats, :user_id, :integer
    remove_index :work_view_stats, :user_id
  end
end
