class ChangeProxyDepositGenericFileIdToWorkId < ActiveRecord::Migration[5.2]
  def change
    rename_column :proxy_deposit_requests, :generic_file_id, :work_id
  end
end
