class CreateProxyDepositRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :proxy_deposit_requests do |t|
      t.string :generic_file_id, null: false
      t.references :sending_user, null: false
      t.references :receiving_user, null: false
      t.datetime :fulfillment_date
      t.string :status, null: false, default: 'pending'
      t.text :sender_comment
      t.text :receiver_comment
      t.timestamps null: false
    end
    
  end
end
