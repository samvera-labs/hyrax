class AddLdapAttrsToUser < ActiveRecord::Migration[5.2]
  def self.up
    add_column :users, :display_name, :string
    add_column :users, :address, :string
    add_column :users, :admin_area, :string
    add_column :users, :department, :string
    add_column :users, :title, :string
    add_column :users, :office, :string
    add_column :users, :chat_id, :string
    add_column :users, :website, :string
    add_column :users, :affiliation, :string
    add_column :users, :telephone, :string
  end

  def self.down
    remove_column :users, :display_name
    remove_column :users, :address
    remove_column :users, :admin_area
    remove_column :users, :department
    remove_column :users, :title
    remove_column :users, :office
    remove_column :users, :chat_id
    remove_column :users, :website
    remove_column :users, :affiliation
    remove_column :users, :telephone
  end
end
