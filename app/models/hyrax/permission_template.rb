# frozen_string_literal: true
module Hyrax
  ##
  # Defines behavior that is applied to objects added as members of an AdminSet
  #
  #  * access rights to stamp on each object
  #  * calculate embargo/lease release dates
  #
  # There is an interplay between an AdminSet and a PermissionTemplate.
  #
  # @see Hyrax::AdminSet for further discussion
  class PermissionTemplate < ActiveRecord::Base # rubocop:disable Metrics/ClassLength
    self.table_name = 'permission_templates'

    has_many :access_grants, class_name: 'Hyrax::PermissionTemplateAccess', dependent: :destroy
    accepts_nested_attributes_for :access_grants, reject_if: :all_blank

    ##
    # @api public
    #
    # Retrieve the agent_ids associated with the given agent_type and access
    #
    # @param [String] agent_type
    # @param [String] access
    #
    # @return [Array<String>] of agent_ids that match the given parameters
    def agent_ids_for(agent_type:, access:)
      access_grants.where(agent_type: agent_type, access: access).pluck(:agent_id)
    end

    # The list of workflows that could be activated; It includes the active workflow
    has_many :available_workflows, class_name: 'Sipity::Workflow', dependent: :destroy

    # In a perfect world, there would be a join table that enforced uniqueness on the ID.
    has_one :active_workflow, -> { where(active: true) }, class_name: 'Sipity::Workflow', foreign_key: :permission_template_id

    ##
    # @note this is a convenience method for +Hyrax.query_service.find_by(id: template.source_id)+
    #
    # @return [Hyrax::Resource] the collection this template is associated with
    def source
      Hyrax.query_service.find_by(id: source_id)
    end

    ##
    # A bit of an analogue for a `belongs_to :source_model` as it crosses from Fedora to the DB
    # @return [AdminSet, ::Collection]
    # @raise [Hyrax::ObjectNotFoundError] when neither an AdminSet or Collection is found
    def source_model
      ActiveFedora::Base.find(source_id)
    rescue ActiveFedora::ObjectNotFoundError
      raise Hyrax::ObjectNotFoundError
    end

    # A bit of an analogue for a `belongs_to :admin_set` as it crosses from Fedora to the DB
    # @deprecated Use #source_model instead
    # @return [AdminSet]
    # @raise [Hyrax::ObjectNotFoundError] when the we cannot find the AdminSet
    def admin_set
      Deprecation.warn('Use #source_model instead')
      return AdminSet.find(source_id) if AdminSet.exists?(source_id)
      raise Hyrax::ObjectNotFoundError
    rescue ActiveFedora::ActiveFedoraError # TODO: remove the rescue when active_fedora issue #1276 is fixed
      raise Hyrax::ObjectNotFoundError
    end

    # A bit of an analogue for a `belongs_to :collection` as it crosses from Fedora to the DB
    # @deprecated Use #source_model instead
    # @return [Collection]
    # @raise [Hyrax::ObjectNotFoundError] when the we cannot find the Collection
    def collection
      Deprecation.warn('Use #source_model instead')
      return ::Collection.find(source_id) if ::Collection.exists?(source_id)
      raise Hyrax::ObjectNotFoundError
    rescue ActiveFedora::ActiveFedoraError # TODO: remove the rescue when active_fedora issue #1276 is fixed
      raise Hyrax::ObjectNotFoundError
    end

    # Valid Release Period values
    RELEASE_TEXT_VALUE_FIXED = 'fixed'
    RELEASE_TEXT_VALUE_NO_DELAY = 'now'

    # Valid Release Varies sub-options
    RELEASE_TEXT_VALUE_BEFORE_DATE = 'before'
    RELEASE_TEXT_VALUE_EMBARGO = 'embargo'
    RELEASE_TEXT_VALUE_6_MONTHS = '6mos'
    RELEASE_TEXT_VALUE_1_YEAR = '1yr'
    RELEASE_TEXT_VALUE_2_YEARS = '2yrs'
    RELEASE_TEXT_VALUE_3_YEARS = '3yrs'

    # Key/value pair of valid embargo periods. Values are number of months embargoed.
    RELEASE_EMBARGO_PERIODS = {
      RELEASE_TEXT_VALUE_6_MONTHS => 6,
      RELEASE_TEXT_VALUE_1_YEAR => 12,
      RELEASE_TEXT_VALUE_2_YEARS => 24,
      RELEASE_TEXT_VALUE_3_YEARS => 36
    }.freeze

    # Does this permission template require a specific date of release for all works
    # NOTE: date will be in release_date
    def release_fixed_date?
      release_period == RELEASE_TEXT_VALUE_FIXED
    end

    # Does this permission template require no release delays (i.e. no embargoes allowed)
    def release_no_delay?
      release_period == RELEASE_TEXT_VALUE_NO_DELAY
    end

    # Does this permission template require a date (or embargo) that all works are released before
    # NOTE: date will be in release_date
    def release_before_date?
      # All PermissionTemplate embargoes are dynamically determined release before dates
      release_period == RELEASE_TEXT_VALUE_BEFORE_DATE || release_max_embargo?
    end

    # Is there a maximum embargo period specified by this permission template
    # NOTE: latest embargo date returned by release_date, maximum embargo period will be in release_period
    def release_max_embargo?
      # Is it a release period in one of our valid embargo periods?
      RELEASE_EMBARGO_PERIODS.key?(release_period)
    end

    # Override release_date getter to return a dynamically calculated date of release
    # based one release requirements. Returns embargo date when release_max_embargo?==true.
    # Returns today's date when release_no_delay?==true.
    # @see Hyrax::AdminSetService for usage
    def release_date
      # If no release delays allowed, return today's date as release date
      return Time.zone.today if release_no_delay?

      # If this isn't an embargo, just return release_date from database
      return self[:release_date] unless release_max_embargo?

      # Otherwise (if an embargo), return latest embargo date by adding specified months to today's date
      Time.zone.today + RELEASE_EMBARGO_PERIODS.fetch(release_period).months
    end

    # Determines whether a given release date is valid based on this template's requirements
    # @param [Date] date to validate
    def valid_release_date?(date)
      # Validate date against all release date requirements
      check_no_delay_requirements(date) && check_before_date_requirements(date) && check_fixed_date_requirements(date)
    end

    # Determines whether a given visibility setting is valid based on this template's requirements
    # @param [String] value - visibility value to validate
    def valid_visibility?(value)
      # If template doesn't specify a visiblity (i.e. is "varies"), then any visibility is valid
      return true if visibility.blank?

      # Validate that passed in value matches visibility requirement exactly
      visibility == value
    end

    ##
    # @return [Array<String>]
    def edit_users
      agent_ids_for(access: 'manage', agent_type: 'user')
    end

    ##
    # @return [Array<String>]
    def edit_groups
      agent_ids_for(access: 'manage', agent_type: 'group')
    end

    ##
    # @return [Array<String>]
    def read_users
      (agent_ids_for(access: 'view', agent_type: 'user') +
        agent_ids_for(access: 'deposit', agent_type: 'user')).uniq
    end

    ##
    # @return [Array<String>]
    def read_groups
      (agent_ids_for(access: 'view', agent_type: 'group') +
        agent_ids_for(access: 'deposit', agent_type: 'group')).uniq -
        [::Ability.registered_group_name, ::Ability.public_group_name]
    end

    ##
    # @return [Boolean]
    def reset_access_controls(interpret_visibility: false)
      reset_access_controls_for(collection: source_model,
                                interpret_visibility: interpret_visibility)
    end

    ##
    # @return [Boolean]
    def reset_access_controls_for(collection:, interpret_visibility: false)
      interpreted_read_groups = read_groups

      if interpret_visibility
        visibilities = Hyrax::VisibilityMap.instance
        interpreted_read_groups -= visibilities.deletions_for(visibility: collection.visibility)
        interpreted_read_groups += visibilities.additions_for(visibility: collection.visibility)
      end

      collection.update!(edit_users: edit_users,
                         edit_groups: edit_groups,
                         read_users: read_users,
                         read_groups: interpreted_read_groups.uniq)
    end

    private

    # If template requires no delays, check if date is exactly today
    def check_no_delay_requirements(date)
      return true unless release_no_delay?
      date == Time.zone.today
    end

    # If template requires a release before a specific date, check this date is valid
    def check_before_date_requirements(date)
      return true unless release_before_date? && release_date.present?
      date <= release_date
    end

    # If template requires an exact date, check this date matches
    def check_fixed_date_requirements(date)
      return true unless release_fixed_date? && release_date.present?
      date == release_date
    end
  end
end
