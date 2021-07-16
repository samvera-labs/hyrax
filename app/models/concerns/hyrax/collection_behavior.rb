# frozen_string_literal: true
module Hyrax
  module CollectionBehavior
    extend ActiveSupport::Concern
    include Hydra::AccessControls::WithAccessRight
    include Hydra::WithDepositor # for access to apply_depositor_metadata
    include Hyrax::CoreMetadata
    include Hydra::Works::CollectionBehavior
    include Hyrax::Noid
    include Hyrax::HumanReadableType
    include Hyrax::HasRepresentative
    include Hyrax::Permissions
    include Hyrax::CollectionNesting

    included do
      validates_with HasOneTitleValidator
      after_destroy :destroy_permission_template

      self.indexer = Hyrax::CollectionIndexer

      class_attribute :index_collection_type_gid_as, writer: false
      self.index_collection_type_gid_as = [:symbol]

      property :collection_type_gid, predicate: ::RDF::Vocab::SCHEMA.additionalType, multiple: false do |index|
        index.as(*index_collection_type_gid_as)
      end

      # validates that collection_type_gid is present
      validates :collection_type_gid, presence: true

      # Need to define here in order to override setter defined by ActiveTriples
      def collection_type_gid=(new_collection_type_gid, force: false)
        new_collection_type_gid = new_collection_type_gid&.to_s
        raise "Can't modify collection type of this collection" if !force && persisted? && !collection_type_gid_was.nil? && collection_type_gid_was != new_collection_type_gid
        new_collection_type = Hyrax::CollectionType.find_by_gid!(new_collection_type_gid)
        super(new_collection_type_gid)
        @collection_type = new_collection_type
        collection_type_gid
      end
    end

    delegate(*Hyrax::CollectionType.settings_attributes, to: :collection_type)

    # Get the collection_type when accessed
    def collection_type
      @collection_type ||= Hyrax::CollectionType.find_by_gid!(collection_type_gid)
    end

    def collection_type=(new_collection_type)
      self.collection_type_gid = new_collection_type.to_global_id
    end

    # Add members using the members association.
    # TODO: Confirm if this is ever used.  I believe all relationships are done through
    #       add_member_objects using the member_of_collections relationship.  Deprecate?
    def add_members(new_member_ids)
      return if new_member_ids.blank?
      members << Hyrax.custom_queries.find_many_by_alternate_ids(alternate_ids: new_member_ids, use_valkyrie: false)
    end

    # Add member objects by adding this collection to the objects' member_of_collection association.
    # @param [Enumerable<String>] the ids of the new child collections and works collection ids
    def add_member_objects(new_member_ids)
      Array(new_member_ids).collect do |member_id|
        member = Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: member_id, use_valkyrie: false)
        message = Hyrax::MultipleMembershipChecker.new(item: member).check(collection_ids: id, include_current_members: true)
        if message
          member.errors.add(:collections, message)
        else
          member.member_of_collections << self
          member.save!
        end
        member
      end
    end

    # @return [Enumerable<ActiveFedora::Base>] an enumerable over the children of this collection
    def member_objects
      ActiveFedora::Base.where("member_of_collection_ids_ssim:#{id}")
    end

    # Use this query to get the ids of the member objects (since the containment
    # association has been flipped)
    def member_object_ids
      return [] unless id
      member_objects.map(&:id)
    end

    def to_s
      title.present? ? title.join(' | ') : 'No Title'
    end

    module ClassMethods
      # This governs which partial to draw when you render this type of object
      def _to_partial_path #:nodoc:
        @_to_partial_path ||= begin
          element = ActiveSupport::Inflector.underscore(ActiveSupport::Inflector.demodulize(name))
          collection = ActiveSupport::Inflector.tableize(name)
          "hyrax/#{collection}/#{element}"
        end
      end

      def collection_type_gid_document_field_name
        Deprecation.warn('use Hyrax.config.collection_type_index_field instead')
        Hyrax.config.collection_type_index_field
      end
    end

    # @deprecated to be removed in 4.0.0; this feature was replaced with a
    #   hard-coded null implementation
    # @return [Fixnum] 0
    def bytes
      Deprecation.warn('#bytes has been deprecated for removal in Hyrax 4.0.0; ' \
                       'The implementation of the indexed Collection size ' \
                       'feature is extremely inefficient, so it has been removed. ' \
                       'This method now returns a hard-coded `0` for compatibility.')
      0
    end

    # @api public
    # Retrieve the permission template for this collection.
    # @return [Hyrax::PermissionTemplate]
    # @raise [ActiveRecord::RecordNotFound]
    def permission_template
      Hyrax::PermissionTemplate.find_by!(source_id: id)
    end

    ##
    # @deprecated use PermissionTemplate#reset_access_controls instead
    #
    # Calculate and update who should have read/edit access to the collections based on who
    # has access in PermissionTemplateAccess
    def reset_access_controls!
      Deprecation.warn("reset_access_controls! is deprecated; use PermissionTemplate#reset_access_controls instead.")

      permission_template
        .reset_access_controls_for(collection: self, interpret_visibility: true)
    end

    private

    # Solr field name works use to index member ids
    def member_ids_field
      "member_ids_ssim"
    end

    def destroy_permission_template
      permission_template.destroy
    rescue ActiveRecord::RecordNotFound
      true
    end
  end
end
