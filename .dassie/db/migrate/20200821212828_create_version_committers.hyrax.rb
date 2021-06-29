class CreateVersionCommitters < ActiveRecord::Migration[5.2]
  def self.up
    create_table :version_committers do |t|
      t.string :obj_id
      t.string :datastream_id
      t.string :version_id
      t.string :committer_login
      t.timestamps null: false
    end
  end

  def self.down
    drop_table :version_committers
  end
end
