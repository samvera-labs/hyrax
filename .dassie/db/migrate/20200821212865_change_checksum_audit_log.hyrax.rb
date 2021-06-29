class ChangeChecksumAuditLog < ActiveRecord::Migration[5.2]
  def change
    rename_column :checksum_audit_logs, :version, :checked_uri
    add_column    :checksum_audit_logs, :passed, :boolean

    reversible do |dir|
      dir.up do
        execute 'UPDATE checksum_audit_logs SET passed = (pass = 1)'
      end
      dir.down do
        execute 'UPDATE checksum_audit_logs SET pass = CASE WHEN passed THEN 1 ELSE 0 END'
      end
    end

    remove_column :checksum_audit_logs, :pass
    add_index     :checksum_audit_logs, :checked_uri
  end
end
