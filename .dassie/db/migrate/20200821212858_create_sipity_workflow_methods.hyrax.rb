class CreateSipityWorkflowMethods < ActiveRecord::Migration[5.2]
  def change
    create_table :sipity_workflow_methods do |t|
      t.string   "service_name",                    null: false
      t.integer  "weight",                          null: false
      t.integer  "workflow_action_id", index: true, null: false
      t.timestamps                                  null: false
    end
  end
end
