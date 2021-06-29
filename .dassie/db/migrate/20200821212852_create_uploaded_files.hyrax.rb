class CreateUploadedFiles < ActiveRecord::Migration[5.2]
  def change
    create_table :uploaded_files do |t|
      t.string :file
      t.references :user, index: true, foreign_key: true
      t.string :file_set_uri, index: true
      t.timestamps null: false
    end
  end
end
