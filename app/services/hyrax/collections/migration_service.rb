# frozen_string_literal: true
module Hyrax
  module Collections
    ##
    # @deprecated this migration tool should no longer be useful after Hyrax 2.1.0; Removal is planned for 4.0
    # Responsible for migrating legacy collections.  Legacy collections are those created before Hyrax 2.1.0 and
    # are identified by the lack of the collection having a collection type gid.
    class MigrationService
      # @api public
      #
      # Migrate all legacy collections to extended collections with collection type assigned.  Legacy collections are those
      # created before Hyrax 2.1.0 and are identified by the lack of the collection having a collection type gid.
      def self.migrate_all_collections
        Deprecation.warn('This migration tool will be removed in Hyrax 4.0.0.')

        Rails.logger.info "*** Migrating #{::Collection.count} collections"
        ::Collection.all.each do |col|
          migrate_collection(col)
          Rails.logger.info "  migrating collection - id: #{col.id}, title: #{col.title}"
        end

        AdminSet.all.each do |adminset|
          migrate_adminset(adminset)
          Rails.logger.info "  migrating adminset - id: #{adminset.id}, title: #{adminset.title}"
        end
        Rails.logger.info "--- Migration Complete"
      end

      # @api private
      #
      # Migrate a single legacy collection to extended collections with collection type assigned.  Legacy collections are those
      # created before Hyrax 2.1.0 and are identified by the lack of the collection having a collection type gid.
      #
      # @param collection [::Collection] collection object to be migrated
      def self.migrate_collection(collection)
        return if collection.collection_type_gid.present? # already migrated
        collection.collection_type_gid = Hyrax::CollectionType.find_or_create_default_collection_type.to_global_id
        create_permissions(collection)
        collection.save
      end
      private_class_method :migrate_collection

      ##
      # @api private
      #
      # Migrate a single adminset to grant depositors and viewers read access to the admin set unless the grant is for
      # registered (authenticated users) or public (anyone) groups.  The adjustment is being made to adminsets created
      # before Hyrax 2.1.0.  Migrating twice will not adversely impact the adminset.
      #
      # @param adminset [AdminSet] adminset object to be migrated
      def self.migrate_adminset(adminset)
        Hyrax::PermissionTemplateAccess.find_or_create_by(permission_template_id: adminset.permission_template.id,
                                                          agent_type: "group", agent_id: "admin", access: "manage")

        adminset.permission_template.reset_access_controls_for(collection: adminset)
      end
      private_class_method :migrate_adminset

      # @api public
      #
      # Validate that migrated collections have both the collection type gid assigned and the permission template with
      # access created and associated with the collection.  Any collection without collection type gid as nil or assigned
      # the default collection type are ignored.
      def self.repair_migrated_collections
        Deprecation.warn('This migration tool will be removed in Hyrax 4.0.0.')

        Rails.logger.info "*** Repairing migrated collections"
        ::Collection.all.each do |col|
          repair_migrated_collection(col)
          Rails.logger.info "  repairing collection - id: #{col.id}, title: #{col.title}"
        end
        AdminSet.all.each do |adminset|
          migrate_adminset(adminset)
          Rails.logger.info "  repairing adminset - id: #{adminset.id}, title: #{adminset.title}"
        end
        Rails.logger.info "--- Repairing Complete"
      end

      # @api private
      #
      # Validate and repair a migrated collection if needed.
      #
      # @param collection [::Collection] collection object to be migrated/repaired
      def self.repair_migrated_collection(collection)
        return if collection.collection_type_gid.present? && collection.collection_type_gid != Hyrax::CollectionType.find_or_create_default_collection_type.to_global_id
        collection.collection_type_gid = Hyrax::CollectionType.find_or_create_default_collection_type.to_global_id
        permission_template = Hyrax::PermissionTemplate.find_by(source_id: collection.id)
        if permission_template.present?
          permission_template.reset_access_controls_for(collection: collection, interpret_visibility: true)
        else
          create_permissions(collection)
        end
        collection.save
      end
      private_class_method :repair_migrated_collection

      # @api private
      #
      # Determine if collection was already migrated.
      #
      # @param [Collection] collection object to be validated
      def self.create_permissions(collection)
        grants = []
        collection.edit_groups.each { |g| grants << { agent_type: 'group', agent_id: g, access: Hyrax::PermissionTemplateAccess::MANAGE } }
        collection.edit_users.each { |u| grants << { agent_type: 'user', agent_id: u, access: Hyrax::PermissionTemplateAccess::MANAGE } }
        collection.read_groups.each { |g| grants << { agent_type: 'group', agent_id: g, access: Hyrax::PermissionTemplateAccess::VIEW } }
        collection.read_users.each { |u| grants << { agent_type: 'user', agent_id: u, access: Hyrax::PermissionTemplateAccess::VIEW } }
        Hyrax::Collections::PermissionsCreateService.create_default(collection: collection, creating_user: ::User.find_by_user_key(collection.depositor), grants: grants)
      end
      private_class_method :create_permissions
    end
  end
end
