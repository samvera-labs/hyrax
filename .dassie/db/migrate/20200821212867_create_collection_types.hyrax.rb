class CreateCollectionTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :hyrax_collection_types do |t|
      t.string :title
      t.text :description
      t.string :machine_id
      t.boolean :nestable, null: false, default: true
      t.boolean :discovery, null: false, default: true
      t.boolean :sharing, null: false, default: true
      t.boolean :multiple_membership, null: false, default: true
      t.boolean :require_membership, null: false, default: false
      t.boolean :workflow, null: false, default: false
      t.boolean :visibility, null: false, default: false
    end
    add_index :hyrax_collection_types, :machine_id
  end
end
