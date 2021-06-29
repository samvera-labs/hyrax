class AddArkivoToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :arkivo_token, :string
    add_column :users, :arkivo_subscription, :string
    add_column :users, :zotero_token, :binary
    add_column :users, :zotero_userid, :string
  end
end
