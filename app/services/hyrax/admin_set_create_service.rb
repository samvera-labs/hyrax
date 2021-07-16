# frozen_string_literal: true
module Hyrax
  # Responsible for creating an AdminSet and its corresponding data:
  #
  # * An associated permission template
  # * Available workflows
  # * An active workflow
  #
  # @see AdminSet
  # @see Hyrax::PermissionTemplate
  # @see Sipity::Workflow
  class AdminSetCreateService
    # @api public
    # Creates the default AdminSet and corresponding data
    # @param admin_set_id [String] The default admin set ID
    # @param title [Array<String>] The title of the default admin set
    # @return [TrueClass]
    # @see AdminSet
    def self.create_default_admin_set(admin_set_id:, title:)
      admin_set = AdminSet.new(id: admin_set_id, title: Array.wrap(title))
      begin
        new(admin_set: admin_set, creating_user: nil).create
      rescue ActiveFedora::IllegalOperation
        # It is possible that another thread created the AdminSet just before this method
        # was called, so ActiveFedora will raise IllegalOperation. In this case we can safely
        # ignore the error.
        Rails.logger.error("AdminSet ID=#{AdminSet::DEFAULT_ID} may or may not have been created due to threading issues.")
      end
    end

    # @api public
    # Creates a non-default AdminSet and corresponding data
    # @param admin_set [AdminSet] the admin set to operate on
    # @param creating_user [User] the user who created the admin set
    # @return [TrueClass, FalseClass] true if it was successful
    # @see AdminSet
    # @raise [RuntimeError] if you attempt to create a default admin set via this mechanism
    def self.call(admin_set:, creating_user:, **kwargs)
      raise "Use .create_default_admin_set to create a default admin set" if admin_set.default_set?
      new(admin_set: admin_set, creating_user: creating_user, **kwargs).create
    end

    # @param admin_set [AdminSet] the admin set to operate on
    # @param creating_user [User] the user who created the admin set (if any).
    # @param workflow_importer [#call] imports the workflow
    def initialize(admin_set:, creating_user:, workflow_importer: default_workflow_importer)
      @admin_set = admin_set
      @creating_user = creating_user
      @workflow_importer = workflow_importer
    end

    attr_reader :creating_user, :admin_set, :workflow_importer

    # Creates an admin set, setting the creator and the default access controls.
    # @return [TrueClass, FalseClass] true if it was successful
    def create
      admin_set.creator = [creating_user.user_key] if creating_user
      admin_set.save.tap do |result|
        if result
          ActiveRecord::Base.transaction do
            permission_template = create_permission_template
            workflow = create_workflows_for(permission_template: permission_template)
            create_default_access_for(permission_template: permission_template, workflow: workflow) if admin_set.default_set?
          end
        end
      end
    end

    private

    def access_grants_attributes
      [
        { agent_type: 'group', agent_id: admin_group_name, access: Hyrax::PermissionTemplateAccess::MANAGE }
      ].tap do |attribute_list|
        # Grant manage access to the creating_user if it exists. Should exist for all but default Admin Set
        attribute_list << { agent_type: 'user', agent_id: creating_user.user_key, access: Hyrax::PermissionTemplateAccess::MANAGE } if creating_user
      end
    end

    def admin_group_name
      ::Ability.admin_group_name
    end

    ##
    # @return [PermissionTemplate]
    def create_permission_template
      permission_template = PermissionTemplate.create!(source_id: admin_set.id, access_grants_attributes: access_grants_attributes)
      permission_template.reset_access_controls_for(collection: admin_set)
      permission_template
    end

    def create_workflows_for(permission_template:)
      workflow_importer.call(permission_template: permission_template)
      grant_all_workflow_roles_to_creating_user_and_admins!(permission_template: permission_template)
      Sipity::Workflow.activate!(permission_template: permission_template, workflow_name: Hyrax.config.default_active_workflow_name)
    end

    # Force creation of registered MANAGING role if it doesn't exist
    def register_managing_role!
      Sipity::Role[Hyrax::RoleRegistry::MANAGING]
    end

    def grant_all_workflow_roles_to_creating_user_and_admins!(permission_template:)
      # This code must be invoked before calling `Sipity::Role.all` or the managing role won't be there
      register_managing_role!
      # Grant all workflow roles to the creating_user and the admin group
      permission_template.available_workflows.each do |workflow|
        Sipity::Role.all.each do |role|
          workflow.update_responsibilities(role: role,
                                           agents: workflow_agents)
        end
      end
    end

    def workflow_agents
      [
        Hyrax::Group.new(admin_group_name)
      ].tap do |agent_list|
        # The default admin set does not have a creating user
        agent_list << creating_user if creating_user
      end
    end

    # Gives deposit access to registered users to default AdminSet
    def create_default_access_for(permission_template:, workflow:)
      permission_template.access_grants.create(agent_type: 'group', agent_id: ::Ability.registered_group_name, access: Hyrax::PermissionTemplateAccess::DEPOSIT)
      deposit = Sipity::Role[Hyrax::RoleRegistry::DEPOSITING]
      workflow.update_responsibilities(role: deposit, agents: Hyrax::Group.new('registered'))
    end

    def default_workflow_importer
      Hyrax::Workflow::WorkflowImporter.method(:load_workflow_for)
    end
  end
end
