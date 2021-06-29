# frozen_string_literal: true
# This migration comes from blacklight (originally 20140202020201)
class CreateSearches < ActiveRecord::Migration[4.2]
  def self.up
    create_table :searches do |t|
      t.binary  :query_params
      t.integer :user_id, index: true
      t.string :user_type

      t.timestamps null: false
    end
  end

  def self.down
    drop_table :searches
  end
end
