class UpdateCollectionTypeColumnOptions < ActiveRecord::Migration[5.2]
  def up
    change_column :hyrax_collection_types, :title, :string, unique: true
    change_column :hyrax_collection_types, :machine_id, :string, unique: true

    remove_index :hyrax_collection_types, :machine_id
    add_index :hyrax_collection_types, :machine_id, unique: true
  end

  def down
    change_column :hyrax_collection_types, :title, :string
    change_column :hyrax_collection_types, :machine_id, :string

    remove_index :hyrax_collection_types, :machine_id
    add_index :hyrax_collection_types, :machine_id
  end
end
