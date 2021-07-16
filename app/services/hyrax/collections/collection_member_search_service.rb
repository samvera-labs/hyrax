# frozen_string_literal: true
module Hyrax
  module Collections
    ##
    # Retrieves collection members
    class CollectionMemberSearchService < Hyrax::SearchService
      ##
      # @param scope [#repository] Typically a controller object which responds to :repository
      # @param [::Collection] collection
      # @param [ActionController::Parameters] params the query params
      # @param [ActionController::Parameters] user_params
      # @param [::Ability] current_ability
      # @param [Class] search_builder_class a {::SearchBuilder}
      def initialize(scope:, collection:, params:, user_params: nil, current_ability: nil, search_builder_class: Hyrax::CollectionMemberSearchBuilder) # rubocop:disable Metrics/ParameterLists
        super(
          config: scope.blacklight_config,
          user_params: user_params || params,
          collection: collection,
          scope: scope,
          current_ability: current_ability || scope.current_ability,
          search_builder_class: search_builder_class
        )
      end

      ##
      # @api public
      #
      # Collections which are members of the given collection
      #
      # @return [Blacklight::Solr::Response] (up to 50 solr documents)
      def available_member_subcollections
        response, _docs = search_results do |builder|
          # To differentiate current page for works vs subcollections, we have to use a sub_collection_page
          # param. Map this to the page param before querying for subcollections, if it's present
          builder.page(user_params[:sub_collection_page])
          builder.search_includes_models = :collections
          builder
        end
        response
      end

      ##
      # @api public
      #
      # Works which are members of the given collection
      #
      # @return [Blacklight::Solr::Response]
      def available_member_works
        response, _docs = search_results do |builder|
          builder.search_includes_models = :works
          builder
        end
        response
      end

      ##
      # @api public
      #
      # Work ids of the works which are members of the given collection
      #
      # @return [Blacklight::Solr::Response]
      def available_member_work_ids
        response, _docs = search_results do |builder|
          builder.search_includes_models = :works
          builder.merge(fl: 'id')
          builder
        end
        response
      end
    end
  end
end
