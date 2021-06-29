class CreateOperations < ActiveRecord::Migration[5.2]
  def change
    create_table :curation_concerns_operations do |t|
      t.string :status
      t.string :operation_type
      t.string :job_class
      t.string :job_id
      t.string :type # For Single Table Inheritance
      t.text :message
      t.references :user, index: true, foreign_key: true

      t.integer :parent_id, null: true, index: true
      t.integer :lft, null: false, index: true
      t.integer :rgt, null: false, index: true

      # optional fields
      t.integer :depth, null: false, default: 0
      t.integer :children_count, null: false, default: 0

      t.timestamps null: false
    end
  end
end
