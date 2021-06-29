class AddPermissionTemplateToSipityWorkflow < ActiveRecord::Migration[5.2]
  def change
    add_column :sipity_workflows, :permission_template_id, :integer, index: true
    remove_index :sipity_workflows, :name
    add_index :sipity_workflows, [:permission_template_id, :name], name: :index_sipity_workflows_on_permission_template_and_name, unique: true
    remove_index :permission_templates, :admin_set_id
    add_index :permission_templates, :admin_set_id, unique: true

    # Only allow one to be true; Note the options should be nil or true to enforce uniqueness
    add_column :sipity_workflows, :active, :boolean, default: nil, index: :unique

    # Doing an inline data migration
    begin
      if Hyrax::PermissionTemplate.column_names.include?('workflow_id')
        Hyrax::PermissionTemplate.each do |permission_template|
          workflow_id = permission_template.workflow_id
          next unless workflow_id
          Sipity::Workflow.find(workflow_id).update(active: true)
        end
        remove_column :permission_templates, :workflow_id
      end
    rescue
      # It's okay, we didn't have the column
    end
  end
end
