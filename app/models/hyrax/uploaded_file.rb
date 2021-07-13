# frozen_string_literal: true
module Hyrax
  ##
  # Store a file uploaded by a user.
  #
  # Eventually these files get attached to {FileSet}s and pushed into Fedora.
  class UploadedFile < ActiveRecord::Base
    self.table_name = 'uploaded_files'
    mount_uploader :file, UploadedFileUploader
    alias uploader file
    has_many :job_io_wrappers,
             inverse_of: 'uploaded_file',
             class_name: 'JobIoWrapper',
             dependent: :destroy
    belongs_to :user, class_name: '::User'

    ##
    # Associate a {FileSet} with this uploaded file.
    #
    # @param [Hyrax::Resource, ActiveFedora::Base] file_set
    # @return [void]
    def add_file_set!(file_set)
      uri = case file_set
            when ActiveFedora::Base
              file_set.uri
            when Hyrax::Resource
              file_set.id
            end
      update!(file_set_uri: uri)
    end

    ##
    # Schedule an IngestJob for this file and the given file_set.
    #
    # @note This was extracted from the Hyrax::WorkUploadsHandler
    #       class.  The aspirational goal is a multi-step consideration:
    #
    # - Reduce branching logic in the controller
    # - Reduce duplication of transaction steps
    #
    # @note This may only be applicable for a Valkyrie resource
    #
    # @todo Refactor to handle both an uploaded_file (current
    #       behavior) and handle a file assigned via BrowseEverything.
    #
    # @param file_set [FileSet]
    # @return [void]
    def perform_ingest_later(file_set:)
      wrapper = JobIoWrapper.create_with_varied_file_handling!(user: user, file: self, relation: :original_file, file_set: file_set)
      IngestJob.perform_later(wrapper)
    end
  end
end
