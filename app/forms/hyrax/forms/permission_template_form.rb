# frozen_string_literal: true
module Hyrax
  module Forms
    class PermissionTemplateForm
      include HydraEditor::Form

      self.model_class = PermissionTemplate
      self.terms = []
      delegate :access_grants, :access_grants_attributes=, :release_date, :release_period, :visibility, to: :model
      delegate :available_workflows, :active_workflow, :source_model, to: :model

      # @return [#to_s] the primary key of the associated admin_set or collection
      # def source_id (because you might come looking for this method)
      delegate :id, to: :source_model, prefix: :source

      ##
      # @deprecated  use PermissionTemplate#reset_access_controls instead.
      def reset_access_controls!
        Deprecation.warn("reset_access_controls! is deprecated; use PermissionTemplate#reset_access_controls instead.")
        source_model.reset_access_controls!
      end

      # Stores which radio button under release "Varies" option is selected
      attr_accessor :release_varies
      # Selected release embargo timeframe (if any) under release "Varies" option
      attr_accessor :release_embargo

      # Stores the selected
      attr_writer :workflow_id

      # Adding attributes hash to state to avoid having to pass it around
      attr_accessor :attributes

      def workflow_id
        @workflow_id || active_workflow.try(:id)
      end

      def visibility_options
        Widgets::AdminSetVisibility.new.options
      end

      def embargo_options
        Widgets::AdminSetEmbargoPeriod.new.options
      end

      def initialize(model)
        super(model)
        # Ensure proper form options selected, based on model
        select_release_varies_option(model)
      end

      # @return [Hash{Symbol => String, Boolean}] { :content_tab (for confirmation message),
      #                                             :updated (true/false),
      #                                               :error_code (for flash error lookup) }
      def update(attributes)
        @attributes = attributes
        return_info = { content_tab: tab_to_update }
        error_code = nil
        case return_info[:content_tab]
        when "participants"
          update_participants_options
        when "visibility"
          error_code = update_visibility_options
        when "workflow"
          grant_workflow_roles
        end
        return_info[:error_code] = error_code if error_code
        return_info[:updated] = error_code ? false : true
        return_info
      end
      # rubocop:enable Metrics/MethodLength

      # Copy this access to the permissions of the Admin Set or Collection and to
      # the WorkflowResponsibilities of the active workflow if this is an Admin Set
      def update_access(remove_agent: false)
        source_model.reset_access_controls!
        update_workflow_responsibilities(remove_agent: remove_agent) if source_model.is_a?(AdminSet)
      end

      # This method is used to revoke access to a Collection or Admin Set and its workflows
      #
      # @return [Void]
      def remove_access!(permission_template_access)
        construct_attributes_from_template_access!(permission_template_access)
        update_access(remove_agent: true)
      end

      private

      # @return [String]
      def tab_to_update
        return "participants" if attributes[:access_grants_attributes].present?
        return "workflow" if attributes[:workflow_id].present?
        return "visibility" if attributes.key?(:visibility)
      end

      # This method is used to build the attributes that this class
      # relies on using the passed-in PermissionTemplateAccess
      # instance. This allows the class to use the same methods for
      # granting access (when a new Admin Set manager is added, for
      # instance), when called via #update, for revoking access as
      # well when called via #remove_access!
      #
      # @return [Void]
      def construct_attributes_from_template_access!(permission_template_access)
        @attributes = {
          access_grants_attributes: {
            "0" => {
              access: permission_template_access.access,
              agent_type: permission_template_access.agent_type,
              agent_id: permission_template_access.agent_id
            }
          }
        }
      end

      # @return [Void]
      def update_participants_options
        update_permission_template
        update_access(remove_agent: false)
      end

      # Grant appropriate workflow roles based on access specified
      def update_workflow_responsibilities(remove_agent: false)
        return unless available_workflows
        roles = roles_for_agent
        return if roles.none?
        agents = remove_agent ? manager_agents - agents_from_attributes : manager_agents + agents_from_attributes
        available_workflows.each do |workflow|
          roles.each do |role|
            workflow.update_responsibilities(role: role, agents: agents)
          end
        end
      end

      def roles_for_agent
        roles = []
        grants_as_collection.each do |grant|
          case grant[:access]
          when Hyrax::PermissionTemplateAccess::DEPOSIT
            roles << Sipity::Role.find_by(name: Hyrax::RoleRegistry::DEPOSITING)
          when Hyrax::PermissionTemplateAccess::MANAGE
            roles += Sipity::Role.where(name: Hyrax::RoleRegistry.new.role_names)
            # TODO: Figure out what to do here
            # when Hyrax::PermissionTemplateAccess::VIEW
          end
        end
        roles.uniq
      end

      # @return [Array<Sipity::Agent>] a list sipity agents extracted from attrs
      def agents_from_attributes
        grants_as_collection.map do |grant|
          agent = if grant[:agent_type] == 'user'
                    ::User.find_by_user_key(grant[:agent_id])
                  else
                    Hyrax::Group.new(grant[:agent_id])
                  end
          Sipity::Agent(agent)
        end
      end

      # @return [Array<Sipity::Agent>] a list of sipity agents corresponding to the manager role of the permission_template
      def manager_agents
        @manager_agents ||= begin
          authorized_agents = manager_grants.map do |access|
            if access.agent_type == 'user'
              ::User.find_by_user_key(access.agent_id)
            else
              Hyrax::Group.new(access.agent_id)
            end
          end

          authorized_agents.map { |agent| Sipity::Agent(agent) }
        end
      end

      # @return [Array<PermissionTemplateAccess>] a list of grants corresponding to the manager role of the permission_template
      def manager_grants
        model.access_grants.where(access: Hyrax::PermissionTemplateAccess::MANAGE)
      end

      # @return [String, Nil] error_code if validation fails, nil otherwise
      def update_visibility_options
        error_code = validate_visibility_combinations
        return error_code if error_code
        update_permission_template
      end

      def activate_workflow_from_attributes
        new_active_workflow_id = attributes[:workflow_id] || attributes['workflow_id']
        if active_workflow
          return active_workflow if new_active_workflow_id.to_s == active_workflow.id.to_s
          Sipity::Workflow.activate!(permission_template: model, workflow_id: new_active_workflow_id)
        elsif new_active_workflow_id
          Sipity::Workflow.activate!(permission_template: model, workflow_id: new_active_workflow_id)
        end
      end

      # If the workflow has been changed, ensure that all the AdminSet managers
      # have all the roles for the new workflow
      # @return [Void]
      # @todo Instead of granting the manage users all of the roles (which means lots of emails), can we agree on a Managing role that all workflows should have?
      def grant_workflow_roles
        new_active_workflow = activate_workflow_from_attributes
        return unless new_active_workflow
        manager_agents.each do |agent|
          active_workflow.workflow_roles.each do |workflow_role|
            new_workflow_role = Sipity::WorkflowRole.find_or_create_by!(workflow: new_active_workflow, role: workflow_role.role)
            Sipity::WorkflowResponsibility.find_or_create_by!(workflow_role: new_workflow_role, agent: agent)
          end
        end
      end

      # @return [Nil]
      def update_permission_template
        model.update(permission_template_update_params)
        nil
      end

      def managers_updated?
        grants_as_collection.any? { |x| x[:access] == Hyrax::PermissionTemplateAccess::MANAGE }
      end

      # This allows the attributes
      def grants_as_collection
        return [] unless attributes[:access_grants_attributes]
        attributes_collection = attributes[:access_grants_attributes]
        attributes_collection = attributes_collection.to_h if attributes_collection.respond_to?(:permitted?)
        if attributes_collection.is_a? Hash
          attributes_collection = attributes_collection
                                  .sort_by { |i, _| i.to_i }
                                  .map { |_, attrs| attrs }
        end
        attributes_collection
      end

      # In form, select appropriate radio button under Release "Varies" option based on saved permission_template
      def select_release_varies_option(permission_template)
        # Ignore 'no_delay' or 'fixed' values, as they are separate options
        return if permission_template.release_no_delay? || permission_template.release_fixed_date?

        # If embargo specified, then 'embargo' option under "varies" was selected and embargo period selected
        if permission_template.release_max_embargo?
          # If release_period is some other value, it is specifying an embargo period (e.g. 6mos, 1yr, etc)
          @release_varies = Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO
          @release_embargo = permission_template.release_period
        # Else If release_period BEFORE a specified date, then 'before' option under "varies" was selected
        elsif permission_template.release_before_date?
          @release_varies = Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE
        end
      end

      # Handles complex defaults
      # Removes release_varies and release_embargo from the returned attributes
      # These form fields are only used to update release_period
      # @return [Hash] attributes used to update the model
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def permission_template_update_params
        filtered_attributes = attributes.except(:release_varies, :release_embargo)
        # If 'varies' before date option selected, then set release_period='before' and save release_date as-is
        if attributes[:release_varies] == Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE
          filtered_attributes[:release_period] = Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE
        # Else if 'varies' + embargo selected, save embargo as the release_period
        elsif attributes[:release_varies] == Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO &&
              attributes[:release_embargo]
          filtered_attributes[:release_period] = attributes[:release_embargo]
          # In an embargo, the release_date should be unspecified as it is based on deposit date
          filtered_attributes[:release_date] = nil
        end

        if filtered_attributes[:release_period] == Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY || (filtered_attributes[:release_period].blank? && attributes[:release_varies].blank?)
          # If release is "no delay" or is "varies" and "allow depositor to decide",
          # then a release_date should never be allowed/specified
          filtered_attributes[:release_date] = nil
        end

        filtered_attributes
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      # validate the hash of attributes used to update the visibility tab of the model
      # @return [String, Nil] the error code if invalid, nil if valid
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/AbcSize
      def validate_visibility_combinations
        return unless attributes.key?(:visibility) # only the visibility tab has validations

        # if "save" without any selections - none of the attributes are present
        return "nothing" if !attributes[:release_varies] && !attributes[:release_period] && !attributes[:release_date] && !attributes[:release_embargo]

        # if "varies before" but date not selected
        return "no_date" if attributes[:release_varies] == Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE && attributes[:release_date].blank?

        # if "varies with embargo" but no embargo period
        return "no_embargo" if attributes[:release_varies] == Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO && attributes[:release_embargo].blank?

        # if "fixed" but date not selected
        return "no_date" if attributes[:release_period] == Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED && attributes[:release_date].blank?
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/AbcSize
    end
  end
end
