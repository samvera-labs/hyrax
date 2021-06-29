class CreateCollectionTypeParticipants < ActiveRecord::Migration[5.2]
  def change
    create_table :collection_type_participants do |t|
      t.references :hyrax_collection_type, foreign_key: true, index: {:name => "hyrax_collection_type_id"}
      t.string :agent_type
      t.string :agent_id
      t.string :access
      t.timestamps
    end
  end
end
