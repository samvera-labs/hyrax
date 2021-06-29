class AddOrcidToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :orcid, :string
  end
end
