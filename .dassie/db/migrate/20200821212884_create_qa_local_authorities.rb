class CreateQaLocalAuthorities < ActiveRecord::Migration[5.2]
  def change
    create_table :qa_local_authorities do |t|
      t.string :name

      t.timestamps
    end
    add_index :qa_local_authorities, :name, unique: true
  end
end
