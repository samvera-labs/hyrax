class UpdateCollectionTypeColumnNames < ActiveRecord::Migration[5.2]
  def change
    rename_column :hyrax_collection_types, :discovery, :discoverable
    rename_column :hyrax_collection_types, :sharing, :sharable
    rename_column :hyrax_collection_types, :multiple_membership, :allow_multiple_membership
    rename_column :hyrax_collection_types, :workflow, :assigns_workflow
    rename_column :hyrax_collection_types, :visibility, :assigns_visibility
  end
end
