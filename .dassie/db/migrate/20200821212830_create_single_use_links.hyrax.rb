class CreateSingleUseLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :single_use_links do |t|
      t.string :downloadKey
      t.string :path
      t.string :itemId
      t.datetime :expires

      t.timestamps null: false
    end
  end
end
