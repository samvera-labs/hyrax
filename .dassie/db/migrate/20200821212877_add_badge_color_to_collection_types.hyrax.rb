class AddBadgeColorToCollectionTypes < ActiveRecord::Migration[5.2]
  def change
     add_column :hyrax_collection_types, :badge_color, :string, default: '#663333'
  end
end
