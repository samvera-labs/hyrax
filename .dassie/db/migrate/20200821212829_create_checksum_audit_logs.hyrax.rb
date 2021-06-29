class CreateChecksumAuditLogs < ActiveRecord::Migration[5.2]
  def self.up
    create_table :checksum_audit_logs do |t|
      t.string :file_set_id
      t.string :file_id
      t.string :version
      t.integer :pass
      t.string :expected_result
      t.string :actual_result
      t.timestamps null: false
    end
    add_index :checksum_audit_logs, [:file_set_id, :file_id], name: 'by_file_set_id_and_file_id', order: { created_at: 'DESC' }
  end

  def self.down
    remove_index(:checksum_audit_logs, name: 'by_file_set_id_and_file_id')
    drop_table :checksum_audit_logs
  end
end
