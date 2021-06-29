class AddPreferredLocaleToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :preferred_locale, :string
  end
end
