class AddReleaseToPermissionTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :permission_templates, :release_date, :date
    add_column :permission_templates, :release_period, :string
  end
end
