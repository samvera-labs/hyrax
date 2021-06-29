# frozen_string_literal: true
# This migration comes from noid_rails_engine (originally 20161021203429)

class RenameMinterStateRandomToRand < ActiveRecord::Migration[4.2]
  def change
    rename_column :minter_states, :random, :rand
  end
end
