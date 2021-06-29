class CreateJobIoWrappers < ActiveRecord::Migration[5.2]
  def change
    create_table :job_io_wrappers do |t|
      t.references :user
      t.references :uploaded_file
      t.string :file_set_id
      t.string :mime_type
      t.string :original_name
      t.string :path
      t.string :relation

      t.timestamps
    end
  end
end
