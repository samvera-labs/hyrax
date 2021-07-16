# frozen_string_literal: true
require 'iiif_manifest'

module Hyrax
  module WorksControllerBehavior
    extend ActiveSupport::Concern
    include Blacklight::Base
    include Blacklight::AccessControls::Catalog

    included do
      with_themed_layout :decide_layout
      copy_blacklight_config_from(::CatalogController)

      class_attribute :_curation_concern_type, :show_presenter, :work_form_service, :search_builder_class
      class_attribute :iiif_manifest_builder, instance_accessor: false
      self.show_presenter = Hyrax::WorkShowPresenter
      self.work_form_service = Hyrax::WorkFormService
      self.search_builder_class = WorkSearchBuilder
      self.iiif_manifest_builder = nil
      attr_accessor :curation_concern
      helper_method :curation_concern, :contextual_path

      rescue_from WorkflowAuthorizationException, with: :render_unavailable
    end

    class_methods do
      def curation_concern_type=(curation_concern_type)
        load_and_authorize_resource class: curation_concern_type, instance_name: :curation_concern, except: [:show, :file_manager, :inspect_work, :manifest]

        # Load the fedora resource to get the etag.
        # No need to authorize for the file manager, because it does authorization via the presenter.
        load_resource class: curation_concern_type, instance_name: :curation_concern, only: :file_manager

        self._curation_concern_type = curation_concern_type
        # We don't want the breadcrumb action to occur until after the concern has
        # been loaded and authorized
        before_action :save_permissions, only: :update
      end

      def curation_concern_type
        _curation_concern_type
      end

      def cancan_resource_class
        Hyrax::ControllerResource
      end
    end

    def new
      # TODO: move these lines to the work form builder in Hyrax
      curation_concern.depositor = current_user.user_key
      curation_concern.admin_set_id = admin_set_id_for_new
      build_form
    end

    def create
      # Caching the original input params in case the form is not valid
      original_input_params_for_form = params[hash_key_for_curation_concern].deep_dup
      if create_work
        after_create_response
      else
        respond_to do |wants|
          wants.html do
            build_form
            # Creating a form object that can re-render most of the
            # submitted parameters
            @form = Hyrax::Forms::FailedSubmissionFormWrapper.new(form: @form, input_params: original_input_params_for_form)
            render 'new', status: :unprocessable_entity
          end
          wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: curation_concern.errors }) }
        end
      end
    end

    # Finds a solr document matching the id and sets @presenter
    # @raise CanCan::AccessDenied if the document is not found or the user doesn't have access to it.
    # rubocop:disable Metrics/AbcSize
    def show
      @user_collections = user_collections

      respond_to do |wants|
        wants.html { presenter && parent_presenter }
        wants.json do
          # load @curation_concern manually because it's skipped for html
          @curation_concern = Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: params[:id])
          curation_concern # This is here for authorization checks (we could add authorize! but let's use the same method for CanCanCan)
          render :show, status: :ok
        end
        additional_response_formats(wants)
        wants.ttl { render body: presenter.export_as_ttl, mime_type: Mime[:ttl] }
        wants.jsonld { render body: presenter.export_as_jsonld, mime_type: Mime[:jsonld] }
        wants.nt { render body: presenter.export_as_nt, mime_type: Mime[:nt] }
      end
    end
    # rubocop:enable Metrics/AbcSize

    def edit
      build_form
    end

    def update
      if update_work
        after_update_response
      else
        respond_to do |wants|
          wants.html do
            build_form
            render 'edit', status: :unprocessable_entity
          end
          wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: curation_concern.errors }) }
        end
      end
    end

    def destroy
      case curation_concern
      when ActiveFedora::Base
        title = curation_concern.to_s
        env = Actors::Environment.new(curation_concern, current_ability, {})
        return unless actor.destroy(env)
        Hyrax.config.callback.run(:after_destroy, curation_concern.id, current_user, warn: false)
      else
        transactions['work_resource.destroy']
          .with_step_args('work_resource.delete' => { user: current_user })
          .call(curation_concern)
          .value!

        title = Array(curation_concern.title).first
      end

      after_destroy_response(title)
    end

    def file_manager
      @form = Forms::FileManagerForm.new(curation_concern, current_ability)
    end

    def inspect_work
      raise Hydra::AccessDenied unless current_ability.admin?
      presenter
    end

    def manifest
      headers['Access-Control-Allow-Origin'] = '*'

      json = iiif_manifest_builder.manifest_for(presenter: iiif_manifest_presenter)

      respond_to do |wants|
        wants.json { render json: json }
        wants.html { render json: json }
      end
    end

    private

    def iiif_manifest_builder
      self.class.iiif_manifest_builder ||
        (Flipflop.cache_work_iiif_manifest? ? Hyrax::CachingIiifManifestBuilder.new : Hyrax::ManifestBuilderService.new)
    end

    def iiif_manifest_presenter
      IiifManifestPresenter.new(search_result_document(id: params[:id])).tap do |p|
        p.hostname = request.base_url
        p.ability = current_ability
      end
    end

    def user_collections
      collections_service.search_results(:deposit)
    end

    def collections_service
      Hyrax::CollectionsService.new(self)
    end

    def admin_set_id_for_new
      # admin_set_id is required on the client, otherwise simple_form renders a blank option.
      # however it isn't a required field for someone to submit via json.
      # Set the default admin set if it exists; otherwise, set to first admin_set they have access to.
      admin_sets = Hyrax::AdminSetService.new(self).search_results(:deposit)
      return nil if admin_sets.blank? # shouldn't happen
      return AdminSet::DEFAULT_ID if admin_sets.map(&:id).include?(AdminSet::DEFAULT_ID)
      admin_sets.first.id
    end

    def build_form
      @form = work_form_service.build(curation_concern, current_ability, self)
    end

    def actor
      @actor ||= Hyrax::CurationConcern.actor
    end

    ##
    # @return [#errors]
    def create_work
      case curation_concern
      when ActiveFedora::Base
        actor.create(actor_environment)
      else
        form = build_form

        @curation_concern =
          form.validate(params[hash_key_for_curation_concern]) &&
          normalize_uploaded_files! &&
          transactions['change_set.create_work']
          .with_step_args('work_resource.add_to_parent' => { parent_id: params[:parent_id], user: current_user },
                          'work_resource.add_file_sets' => { uploaded_files: uploaded_files, file_set_params: params[hash_key_for_curation_concern][:file_set] },
                          'change_set.set_user_as_depositor' => { user: current_user })
          .call(form).value!
      end
    end

    def update_work
      case curation_concern
      when ActiveFedora::Base
        actor.update(actor_environment)
      else
        form = build_form

        @curation_concern =
          form.validate(params[hash_key_for_curation_concern]) &&
          normalize_uploaded_files! &&
          transactions['change_set.update_work']
          .with_step_args('work_resource.add_file_sets' => { uploaded_files: uploaded_files, file_set_params: params[hash_key_for_curation_concern][:file_set] })
          .call(form).value!
      end
    end

    def presenter
      @presenter ||= show_presenter.new(search_result_document(id: params[:id]), current_ability, request)
    end

    def parent_presenter
      return @parent_presenter unless params[:parent_id]

      @parent_presenter ||=
        show_presenter.new(search_result_document(id: params[:parent_id]), current_ability, request)
    end

    # Include 'hyrax/base' in the search path for views, while prefering
    # our local paths. Thus we are unable to just override `self.local_prefixes`
    def _prefixes
      @_prefixes ||= super + ['hyrax/base']
    end

    def actor_environment
      Actors::Environment.new(curation_concern, current_ability, attributes_for_actor)
    end

    def hash_key_for_curation_concern
      _curation_concern_type.model_name.param_key
    end

    def contextual_path(presenter, parent_presenter)
      ::Hyrax::ContextualPath.new(presenter, parent_presenter).show
    end

    # @deprecated
    def curation_concern_from_search_results
      Deprecation.warn("'##{__method__}' will be removed in Hyrax 4.0.  " \
                       "Instead, use '#search_result_document'.")
      search_params = params.deep_dup
      search_params.delete :page
      search_result_document(search_params)
    end

    ##
    # Only returns unsuppressed documents the user has read access to
    #
    # @api public
    #
    # @param search_params [ActionController::Parameters] this should
    #   include an :id key, but based on implementation and use of the
    #   WorkSearchBuilder, it need not.
    #
    # @return [SolrDocument]
    #
    # @raise [WorkflowAuthorizationException] when the object is not
    #   found via the search builder's search logic BUT the object is
    #   suppressed AND the user can read it (Yeah, it's confusing but
    #   after a lot of debugging that's the logic)
    #
    # @raise [CanCan::AccessDenied] when the object is not found via
    #   the search builder's search logic BUT the object is not
    #   supressed OR not readable by the user (Yeah.)
    #
    # @note This is Jeremy, I have suspicions about the first line of
    #   this comment (eg, "Only return unsuppressed...").  The
    #   reason is that I've encounter situations in the specs
    #   where the document_list is empty but if I then query Solr
    #   for the object by ID, I get a document that is NOT
    #   suppressed AND can be read.  In other words, I believe
    #   there is more going on in the search_results method
    #   (e.g. a filter is being applied that is beyond what the
    #   comment indicates)
    #
    # @see #document_not_found!
    def search_result_document(search_params)
      _, document_list = search_results(search_params)
      return document_list.first unless document_list.empty?
      document_not_found!
    end

    def document_not_found!
      doc = ::SolrDocument.find(params[:id])
      raise WorkflowAuthorizationException if doc.suppressed? && current_ability.can?(:read, doc)
      raise CanCan::AccessDenied.new(nil, :show)
    end

    def render_unavailable
      message = I18n.t("hyrax.workflow.unauthorized")
      respond_to do |wants|
        wants.html do
          unavailable_presenter
          flash[:notice] = message
          render 'unavailable', status: :unauthorized
        end
        wants.json { render plain: message, status: :unauthorized }
        additional_response_formats(wants)
        wants.ttl { render plain: message, status: :unauthorized }
        wants.jsonld { render plain: message, status: :unauthorized }
        wants.nt { render plain: message, status: :unauthorized }
      end
    end

    def unavailable_presenter
      @presenter ||= show_presenter.new(::SolrDocument.find(params[:id]), current_ability, request)
    end

    def decide_layout
      layout = case action_name
               when 'show'
                 '1_column'
               else
                 'dashboard'
               end
      File.join(theme, layout)
    end

    ##
    # @todo should the controller know so much about browse_everything?
    #   hopefully this can be refactored to be more reusable.
    #
    # Add uploaded_files to the parameters received by the actor.
    def attributes_for_actor # rubocop:disable Metrics/MethodLength
      raw_params = params[hash_key_for_curation_concern]
      attributes = if raw_params
                     work_form_service.form_class(curation_concern).model_attributes(raw_params)
                   else
                     {}
                   end

      # If they selected a BrowseEverything file, but then clicked the
      # remove button, it will still show up in `selected_files`, but
      # it will no longer be in uploaded_files. By checking the
      # intersection, we get the files they added via BrowseEverything
      # that they have not removed from the upload widget.
      uploaded_files = params.fetch(:uploaded_files, [])
      selected_files = params.fetch(:selected_files, {}).values
      browse_everything_urls = uploaded_files &
                               selected_files.map { |f| f[:url] }

      # we need the hash of files with url and file_name
      browse_everything_files = selected_files
                                .select { |v| uploaded_files.include?(v[:url]) }
      attributes[:remote_files] = browse_everything_files
      # Strip out any BrowseEverthing files from the regular uploads.
      attributes[:uploaded_files] = uploaded_files -
                                    browse_everything_urls
      attributes
    end

    ##
    # There are two means of "uploading" files:
    #
    # 1. via CarrierWave (e.g., upload in the HTML form)
    # 2. via BrowseEverything (e.g., select files and later upload
    #    those URLs)
    #
    # This method seeks to somewhat normalize the uploaded files by
    # creating Hyrax::UploadedFile entries for the BrowseEverthing
    # files.  Doing this minimizes branching logic up until the
    # application stack is ready to attach the binary to the
    # corresponding Hyrax::FileSet.
    #
    # @note at this point, this is a Valkyrie only path.  Perhaps a
    # later refactor will go down the ActiveFedora path.
    def normalize_uploaded_files!
      # If they selected a BrowseEverything file, but then clicked the
      # remove button, it will still show up in `selected_files`, but
      # it will no longer be in uploaded_files. By checking the
      # intersection, we get the files they added via BrowseEverything
      # that they have not removed from the upload widget.
      uploaded_files = params.fetch(:uploaded_files, [])
      params.fetch(:selected_files, {}).each_pair do |_, value|
        next unless uploaded_files.include?(value[:url])

        # This logic mimics the behavior of CarrierWave, namely creating an ActiveRecord record for later
        # ingest.  In this case, we're swapping out the given URL for the record ID.  Downstream, we'll
        # act on the URL.
        uploaded_file = UploadedFile.create!(user: current_user, url_of_remote_file_for_ingest: value[:url])
        uploaded_files.delete(value[:url])
        uploaded_files << uploaded_file.to_param
      end
      # Need to ensure that we swap out the URLs for the UploadedFile's we created above.  The uploaded_files local
      # variable is a copy of the params[:uploaded_file] (e.g., they don't have the same object_id)
      params[:uploaded_files] = uploaded_files unless uploaded_files.empty?
      true
    end

    def after_create_response
      respond_to do |wants|
        wants.html do
          # Calling `#t` in a controller context does not mark _html keys as html_safe
          flash[:notice] = view_context.t('hyrax.works.create.after_create_html', application_name: view_context.application_name)

          redirect_to [main_app, curation_concern]
        end
        wants.json { render :show, status: :created, location: polymorphic_path([main_app, curation_concern]) }
      end
    end

    def after_update_response
      return redirect_to hyrax.confirm_access_permission_path(curation_concern) if permissions_changed? && concern_has_file_sets?

      respond_to do |wants|
        wants.html { redirect_to [main_app, curation_concern], notice: "Work \"#{curation_concern}\" successfully updated." }
        wants.json { render :show, status: :ok, location: polymorphic_path([main_app, curation_concern]) }
      end
    end

    def after_destroy_response(title)
      respond_to do |wants|
        wants.html { redirect_to hyrax.my_works_path, notice: "Deleted #{title}" }
        wants.json { render_json_response(response_type: :deleted, message: "Deleted #{curation_concern.id}") }
      end
    end

    def additional_response_formats(format)
      format.endnote do
        send_data(presenter.solr_document.export_as_endnote,
                  type: "application/x-endnote-refer",
                  filename: presenter.solr_document.endnote_filename)
      end
    end

    def save_permissions
      @saved_permissions =
        case curation_concern
        when ActiveFedora::Base
          curation_concern.permissions.map(&:to_hash)
        else
          Hyrax::AccessControl.for(resource: curation_concern).permissions
        end
    end

    def permissions_changed?
      @saved_permissions !=
        case curation_concern
        when ActiveFedora::Base
          curation_concern.permissions.map(&:to_hash)
        else
          Hyrax::AccessControl.for(resource: curation_concern).permissions
        end
    end

    def concern_has_file_sets?
      case curation_concern
      when ActiveFedora::Common
        curation_concern.file_sets.present?
      else
        Hyrax.custom_queries.find_child_fileset_ids(resource: curation_concern).any?
      end
    end

    def uploaded_files
      UploadedFile.find(params.fetch(:uploaded_files, []))
    end
  end
end
