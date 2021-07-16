# frozen_string_literal: true
module Hyrax
  module Collections
    ##
    # Retrieves collection members
    class CollectionMemberService
      ##
      # @param scope [#repository] Typically a controller object which responds to :repository
      # @param [::Collection] collection
      # @param [ActionController::Parameters] params the query params
      # @param [ActionController::Parameters] user_params
      # @param [::Ability] current_ability
      # @param [Class] search_builder_class a {::SearchBuilder}
      def initialize(scope:, collection:, params:, user_params: nil, current_ability: nil, search_builder_class: Hyrax::CollectionMemberSearchBuilder) # rubocop:disable Metrics/ParameterLists
        Deprecation.warn("'##{__method__}' will be removed in Hyrax 4.0.  " \
                         "Instead, use the same method in 'Hyrax::Collections::CollectionMemberSearchService'.")
        @member_search_service = Hyrax::Collections::CollectionMemberSearchService(scope: scope,
                                                                                   collection: collection,
                                                                                   params: params,
                                                                                   user_params: user_params,
                                                                                   current_ability: current_ability,
                                                                                   search_builder_class: search_builder_class)
      end

      ##
      # @api public
      #
      # Collections which are members of the given collection
      #
      # @return [Blacklight::Solr::Response] (up to 50 solr documents)
      def available_member_subcollections
        Deprecation.warn("'##{__method__}' will be removed in Hyrax 4.0.  " \
                         "Instead, use the same method in 'Hyrax::Collections::CollectionMemberSearchService'.")
        @member_search_service.available_member_subcollections
      end

      ##
      # @api public
      #
      # Works which are members of the given collection
      #
      # @return [Blacklight::Solr::Response]
      def available_member_works
        Deprecation.warn("'##{__method__}' will be removed in Hyrax 4.0.  " \
                         "Instead, use the same method in 'Hyrax::Collections::CollectionMemberSearchService'.")
        @member_search_service.available_member_works
      end

      ##
      # @api public
      #
      # Work ids of the works which are members of the given collection
      #
      # @return [Blacklight::Solr::Response]
      def available_member_work_ids
        Deprecation.warn("'##{__method__}' will be removed in Hyrax 4.0.  " \
                         "Instead, use the same method in 'Hyrax::Collections::CollectionMemberSearchService'.")
        @member_search_service.available_member_work_ids
      end
    end
  end
end
