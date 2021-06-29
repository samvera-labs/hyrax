# frozen_string_literal: true
Hyrax.config do |config|
  # Hyrax can integrate with Zotero's Arkivo service for automatic deposit
  # of Zotero-managed research items.
  # Defaults to false.  See README for more info
  config.arkivo_api = true

  # Injected via `rails g hyrax:work GenericWork`
  config.register_curation_concern :generic_work
  # Injected via `rails g hyrax:work NamespacedWorks::NestedWork`
  config.register_curation_concern :"namespaced_works/nested_work"

  config.iiif_image_server = true

  # Returns a URL that resolves to an image provided by a IIIF image server
  config.iiif_image_url_builder = lambda do |file_id, base_url, size|
    Riiif::Engine.routes.url_helpers.image_url(file_id, host: base_url, size: size)
  end

  # Returns a URL that resolves to an info.json file provided by a IIIF image server
  config.iiif_info_url_builder = lambda do |file_id, base_url|
    uri = Riiif::Engine.routes.url_helpers.info_url(file_id, host: base_url)
    uri.sub(%r{/info\.json\Z}, '')
  end

  # If browse-everything has been configured, load the configs.  Otherwise, set to nil.
  begin
    if defined? BrowseEverything
      config.browse_everything = BrowseEverything.config
    else
      Rails.logger.warn "BrowseEverything is not installed"
    end
  rescue Errno::ENOENT
    config.browse_everything = nil
  end
end

Date::DATE_FORMATS[:standard] = "%m/%d/%Y"

Qa::Authorities::Local.register_subauthority('subjects', 'Qa::Authorities::Local::TableBasedAuthority')
Qa::Authorities::Local.register_subauthority('languages', 'Qa::Authorities::Local::TableBasedAuthority')
Qa::Authorities::Local.register_subauthority('genres', 'Qa::Authorities::Local::TableBasedAuthority')
