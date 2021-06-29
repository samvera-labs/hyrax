class CreateFeaturedWorks < ActiveRecord::Migration[5.2]
  def change
    create_table :featured_works do |t|
      t.integer :order, default: 5
      t.string :work_id

      t.timestamps null: false
    end
    add_index :featured_works, :work_id
    add_index :featured_works, :order
  end
end
