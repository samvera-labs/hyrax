# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # Mediates uploads to a work.
  #
  # Given an existing Work object, `#add` some set of files, then call `#attach`
  # to handle creation/attachment of File Sets, and trigger persistence of files
  # to the storage backend.
  #
  # This class provides both an interface and a concrete implementation.
  # Applications that want to handle file attachment differently (e.g. by making
  # them completely synchronous, by attaching file sets to a different work
  # attribute, by supporting another file/IO class, etc...) can use a different
  # `Handler` implementation. The only guarantee made by the _interface_ is that
  # the process of persisting the relationship between `work` and the provided
  # `files` will start when `#attach` is called.
  #
  # This base implementation accepts only `Hyrax::UploadedFile` instances and,
  # for each one, creates a `Hyrax::FileSet` with permissions matching those on
  # `work`, and appends that FileSet to `member_ids`. The `FileSet` will be
  # added in the order that the `UploadedFiles` are passed in. If the work has a
  # `nil` `representative_id` and/or `thumbnail_id`, the first `FileSet` will be
  # set to that value. An `IngestJob` will be equeued, for each `FileSet`. When
  # all of the `files` have been processed, the work will be saved with the
  # added members. While this is happening, we take a lock on the work via
  # `Lockable` (Redis/Redlock).
  #
  # This also publishes events as required by `Hyrax.publisher`.
  #
  # @todo make this genuinely retry-able. if we fail after creating some of
  #   the file_sets, but not attaching them to works, we should resolve that
  #   incomplete work on subsequent runs.
  #
  #
  # @example
  #   Hyrax::WorkUploadsHandler.new(work: my_work)
  #     .add(files: [file1, file2])
  #     .attach
  #
  class WorkUploadsHandler
    include Lockable

    ##
    # @!attribute [r] files
    #   @return [Enumberable<Hyrax::UploadedFile>]
    # @!attribute [r] work
    #   @return [Hyrax::Work]
    # @!attribute [r] file_set_params
    #   @return [Enumerable<Hash>]
    attr_reader :files, :work, :file_set_params

    ##
    # @param [Hyrax::Work] work
    # @param [#save] persister the valkyrie persister to use
    def initialize(work:, persister: Hyrax.persister)
      @work = work
      @persister = persister
    end

    ##
    # @api public
    #
    # @note we immediately and silently discard uploads with an existing
    #   file_set_uri, in a half-considered attempt at supporting idempotency
    #   (for job retries). this is for legacy/AttachFilesToWorkJob
    #   compatibility, but could stand for a robust reimplementation.
    #
    # @param [Enumberable<Hyrax::UploadedFile>] files  files to add
    #
    # @return [WorkFileSetManager] self
    # @raise [ArgumentError] if any of the uploaded files are not an
    #   `UploadedFile`
    def add(files:, file_set_params: [])
      validate_files(files) &&
        @files = Array.wrap(files).reject { |f| f.file_set_uri.present? }
      @file_set_params = file_set_params
      self
    end

    ##
    # @api public
    #
    # Create filesets for each added file
    #
    # @return [Boolean] true if all requested files were attached
    def attach
      return true if Array.wrap(files).empty? # short circuit to avoid aquiring a lock we won't use

      acquire_lock_for(work.id) do
        event_payloads = files.each_with_object([]) { |file, arry| arry << make_file_set_and_ingest(file) }
        @persister.save(resource: work)
        Hyrax.publisher.publish('object.metadata.updated', object: work, user: files.first.user)
        event_payloads.each { |payload| Hyrax.publisher.publish('file.set.attached', payload) }
      end
    end

    private

    ##
    # @api private
    def make_file_set_and_ingest(file)
      file_set = @persister.save(resource: Hyrax::FileSet.new(file_set_args(file)))
      Hyrax.publisher.publish('object.deposited', object: file_set, user: file.user)
      file.add_file_set!(file_set)

      # copy ACLs; should we also be propogating embargo/lease?
      Hyrax::AccessControlList.copy_permissions(source: target_permissions, target: file_set)

      # set visibility from params and save
      file_set.visibility = file_set_extra_params(file)[:visibility] if file_set_extra_params(file)[:visibility].present?
      file_set.permission_manager.acl.save if file_set.permission_manager.acl.pending_changes?
      append_to_work(file_set)

      file.perform_ingest_later(file_set: file_set)
      Hyrax.publisher.publish('object.metadata.updated', object: file_set, user: file.user)

      { file_set: file_set, user: file.user }
    end

    ##
    # @api private
    #
    # @todo figure out how to know less about Work's ideas about FileSet use here. Maybe post-Wings, work.
    def append_to_work(file_set)
      work.member_ids << file_set.id
      work.representative_id = file_set.id if work.respond_to?(:representative_id) && work.representative_id.blank?
      work.thumbnail_id = file_set.id if work.respond_to?(:thumbnail_id) && work.thumbnail_id.blank?
    end

    ##
    # @api private
    #
    # @return [Hash{Symbol => Object}]
    def file_set_args(file)
      { depositor: file.user.user_key,
        creator: file.user.user_key,
        date_uploaded: file.created_at,
        date_modified: Hyrax::TimeService.time_in_utc,
        label: file.uploader.filename,
        title: file.uploader.filename }
    end

    ##
    # @api private
    #
    # return [Hash(Symbol => Object)]
    def file_set_extra_params(file)
      file_set_params&.find { |fs| fs[:uploaded_file_id] == file.id.to_s } || {}
    end

    ##
    # @api private
    #
    # @note cache these per instance to avoid repeated lookups.
    #
    # @return [Hyrax::AccessControlList] permissions to set on created filesets
    def target_permissions
      @target_permissions ||= Hyrax::AccessControlList.new(resource: work)
    end

    ##
    # @api private
    #
    # @note ported from AttachFilesToWorkJob. do we need this? maybe we should
    #   validate something other than type?
    #
    # @raise [ArgumentError] if any of the uploaded files aren't the right class
    def validate_files(files)
      files.each do |file|
        next if file.is_a? Hyrax::UploadedFile
        raise ArgumentError, "Hyrax::UploadedFile required, but #{file.class} received: #{file.inspect}"
      end
    end
  end
end
