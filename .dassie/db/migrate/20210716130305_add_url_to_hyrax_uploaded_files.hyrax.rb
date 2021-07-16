class AddUrlToHyraxUploadedFiles < ActiveRecord::Migration[5.2]
  def change
    add_column :uploaded_files, :url_of_remote_file_for_ingest, :text
  end
end
