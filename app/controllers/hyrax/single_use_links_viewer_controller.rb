# frozen_string_literal: true
module Hyrax
  class SingleUseLinksViewerController < DownloadsController
    include Blacklight::Base
    include Blacklight::AccessControls::Catalog
    include ActionDispatch::Routing::PolymorphicRoutes

    skip_before_action :authorize_download!, only: :show
    rescue_from SingleUseError, with: :render_single_use_error
    rescue_from CanCan::AccessDenied, with: :render_single_use_error
    rescue_from ActiveRecord::RecordNotFound, with: :render_single_use_error
    class_attribute :presenter_class
    self.presenter_class = FileSetPresenter
    copy_blacklight_config_from(::CatalogController)

    configure_blacklight do |config|
      config.search_builder_class = SingleUseLinkSearchBuilder
    end

    def download
      raise not_found_exception unless single_use_link.path == hyrax.download_path(id: @asset)
      send_content
    end

    def show
      # Authorize using SingleUseLinksViewerController::Ability
      authorize! :read, curation_concern
      raise not_found_exception unless single_use_link.path == polymorphic_path([main_app, curation_concern])

      # show the file
      @presenter = presenter_class.new(curation_concern, current_ability)

      # create a dowload link that is single use for the user since we do not just want to show metadata we want to access it too
      @su = single_use_link.create_for_path hyrax.download_path(curation_concern.id)
      @download_link = hyrax.download_single_use_link_path(@su.download_key)
    end

    private

    def curation_concern
      response, _document_list = search_service.search_results
      response.documents.first
    end

    def search_service
      Hyrax::SearchService.new(config: blacklight_config, user_params: { id: single_use_link.item_id }, scope: self)
    end

    def content_options
      super.tap do |options|
        options[:disposition] = 'attachment' if action_name == 'download'
      end
    end

    # This is called in a before filter. It causes @asset to be set.
    def authorize_download!
      authorize! :read, asset
    end

    def single_use_link
      @single_use_link ||= SingleUseLink.find_by_download_key!(params[:id])
    end

    def not_found_exception
      SingleUseError.new('Single-Use Link Not Found')
    end

    def asset
      @asset ||= Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: single_use_link.item_id, use_valkyrie: Hyrax.config.use_valkyrie?)
    end

    def current_ability
      @current_ability ||= SingleUseLinksViewerController::Ability.new current_user, single_use_link
    end

    def render_single_use_error(exception)
      logger.error("Rendering PAGE due to exception: #{exception.inspect} - #{exception.backtrace if exception.respond_to? :backtrace}")
      render 'single_use_error', layout: "error", status: 404
    end

    def _prefixes
      # This allows us to use the attributes templates in hyrax/base, while prefering
      # our local paths. Thus we are unable to just override `self.local_prefixes`
      @_prefixes ||= super + ['hyrax/base']
    end

    class Ability
      include CanCan::Ability

      attr_reader :single_use_link

      def initialize(user, single_use_link)
        @user = user || ::User.new
        return unless single_use_link

        @single_use_link = single_use_link
        can :read, [ActiveFedora::Base, ::SolrDocument] do |obj|
          single_use_link.valid? && single_use_link.item_id == obj.id && single_use_link.destroy!
        end
      end
    end
  end
end
