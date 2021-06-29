# frozen_string_literal: true
class CatalogController < ApplicationController
  include Hydra::Catalog
  include Hydra::Controller::ControllerBehavior

  # This filter applies the hydra access controls
  before_action :enforce_show_permissions, only: :show

  def self.uploaded_field
    "system_create_dtsi"
  end

  def self.modified_field
    "system_modified_dtsi"
  end

  configure_blacklight do |config|
    config.view.gallery.partials = [:index_header, :index]
    config.view.masonry.partials = [:index]
    config.view.slideshow.partials = [:index]


    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    config.show.partials.insert(1, :openseadragon)
    config.search_builder_class = Hyrax::CatalogSearchBuilder

    # Show gallery view
    config.view.gallery.partials = [:index_header, :index]
    config.view.slideshow.partials = [:index]

    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      qt: "search",
      rows: 10,
      qf: "title_tesim description_tesim creator_tesim keyword_tesim"
    }

    # solr field configuration for document/show views
    config.index.title_field = "title_tesim"
    config.index.display_type_field = "has_model_ssim"
    config.index.thumbnail_field = 'thumbnail_path_ss'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    config.add_facet_field "human_readable_type_sim", label: "Type", limit: 5
    config.add_facet_field "resource_type_sim", label: "Resource Type", limit: 5
    config.add_facet_field "creator_sim", limit: 5
    config.add_facet_field "contributor_sim", label: "Contributor", limit: 5
    config.add_facet_field "keyword_sim", limit: 5
    config.add_facet_field "subject_sim", limit: 5
    config.add_facet_field "language_sim", limit: 5
    config.add_facet_field "based_near_label_sim", limit: 5
    config.add_facet_field "publisher_sim", limit: 5
    config.add_facet_field "file_format_sim", limit: 5
    config.add_facet_field "member_of_collection_ids_ssim", limit: 5, label: 'Collections', helper_method: :collection_title_by_id

    # The generic_type and depositor are not displayed on the facet list
    # They are used to give a label to the filters that comes from the user profile
    config.add_facet_field "generic_type_sim", if: false
    config.add_facet_field "depositor_ssim", label: "Depositor", if: false

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field "title_tesim", label: "Title", itemprop: 'name', if: false
    config.add_index_field "description_tesim", itemprop: 'description', helper_method: :iconify_auto_link
    config.add_index_field "keyword_tesim", itemprop: 'keywords', link_to_search: "keyword_sim"
    config.add_index_field "subject_tesim", itemprop: 'about', link_to_search: "subject_sim"
    config.add_index_field "creator_tesim", itemprop: 'creator', link_to_search: "creator_sim"
    config.add_index_field "contributor_tesim", itemprop: 'contributor', link_to_search: "contributor_sim"
    config.add_index_field "proxy_depositor_ssim", label: "Depositor", helper_method: :link_to_profile
    config.add_index_field "depositor_tesim", label: "Owner", helper_method: :link_to_profile
    config.add_index_field "publisher_tesim", itemprop: 'publisher', link_to_search: "publisher_sim"
    config.add_index_field "based_near_label_tesim", itemprop: 'contentLocation', link_to_search: "based_near_label_sim"
    config.add_index_field "language_tesim", itemprop: 'inLanguage', link_to_search: "language_sim"
    config.add_index_field "date_uploaded_dtsi", itemprop: 'datePublished', helper_method: :human_readable_date
    config.add_index_field "date_modified_dtsi", itemprop: 'dateModified', helper_method: :human_readable_date
    config.add_index_field "date_created_tesim", itemprop: 'dateCreated'
    config.add_index_field "rights_statement_tesim", helper_method: :rights_statement_links
    config.add_index_field "license_tesim", helper_method: :license_links
    config.add_index_field "resource_type_tesim", label: "Resource Type", link_to_search: "resource_type_sim"
    config.add_index_field "file_format_tesim", link_to_search: "file_format_sim"
    config.add_index_field "identifier_tesim", helper_method: :index_field_link, field_name: 'identifier'
    config.add_index_field Hydra.config.permissions.embargo.release_date, label: "Embargo release date", helper_method: :human_readable_date
    config.add_index_field Hydra.config.permissions.lease.expiration_date, label: "Lease expiration date", helper_method: :human_readable_date

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field "title_tesim"
    config.add_show_field "description_tesim"
    config.add_show_field "keyword_tesim"
    config.add_show_field "subject_tesim"
    config.add_show_field "creator_tesim"
    config.add_show_field "contributor_tesim"
    config.add_show_field "publisher_tesim"
    config.add_show_field "based_near_label_tesim"
    config.add_show_field "language_tesim"
    config.add_show_field "date_uploaded_tesim"
    config.add_show_field "date_modified_tesim"
    config.add_show_field "date_created_tesim"
    config.add_show_field "rights_statement_tesim"
    config.add_show_field "license_tesim"
    config.add_show_field "resource_type_tesim", label: "Resource Type"
    config.add_show_field "format_tesim"
    config.add_show_field "identifier_tesim"

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.
    #
    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.
    config.add_search_field('all_fields', label: 'All Fields') do |field|
      all_names = config.show_fields.values.map(&:field).join(" ")
      title_name = "title_tesim"
      field.solr_parameters = {
        qf: "#{all_names} file_format_tesim all_text_timv",
        pf: title_name.to_s
      }
    end

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.
    # creator, title, description, publisher, date_created,
    # subject, language, resource_type, format, identifier, based_near,
    config.add_search_field('contributor') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      solr_name = "contributor_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('creator') do |field|
      solr_name = "creator_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('title') do |field|
      solr_name = "title_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('description') do |field|
      field.label = "Description"
      solr_name = "description_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('publisher') do |field|
      solr_name = "publisher_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('date_created') do |field|
      solr_name = "created_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('subject') do |field|
      solr_name = "subject_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('language') do |field|
      solr_name = "language_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('resource_type') do |field|
      solr_name = "resource_type_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('format') do |field|
      solr_name = "format_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('identifier') do |field|
      solr_name = "id_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('based_near') do |field|
      field.label = "Location"
      solr_name = "based_near_label_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('keyword') do |field|
      solr_name = "keyword_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('depositor') do |field|
      solr_name = "depositor_ssim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('rights_statement') do |field|
      solr_name = "rights_statement_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('license') do |field|
      solr_name = "license_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value
    config.add_sort_field "score desc, #{uploaded_field} desc", label: "relevance"
    config.add_sort_field "#{uploaded_field} desc", label: "date uploaded \u25BC"
    config.add_sort_field "#{uploaded_field} asc", label: "date uploaded \u25B2"
    config.add_sort_field "#{modified_field} desc", label: "date modified \u25BC"
    config.add_sort_field "#{modified_field} asc", label: "date modified \u25B2"

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  # disable the bookmark control from displaying in gallery view
  # Hyrax doesn't show any of the default controls on the list view, so
  # this method is not called in that context.
  def render_bookmarks_control?
    false
  end
end
