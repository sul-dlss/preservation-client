# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'moab'
require 'tempfile'

# NOTE:  this class makes use of data structures from moab-versioning gem,
#  but it does NOT directly access any preservation storage roots
module Preservation
  class Client
    # API calls that are about Preserved Objects
    class Objects < VersionedApiService # rubocop:disable Metrics/ClassLength
      def initialize(connection:, streaming_connection:, retry_max:, retry_interval:, api_version: DEFAULT_API_VERSION)
        super(connection: connection, streaming_connection: streaming_connection, api_version: api_version)
        @retry_max = retry_max
        @retry_interval = retry_interval
      end

      # @param [String] druid - with or without prefix: 'druid:bb123cd4567' OR 'bb123cd4567'
      # @return [Hash] the checksums and filesize for the druid
      def checksum(druid:)
        get_json("objects/#{druid}/checksum", druid)
      end

      # @param [String] druid - with or without prefix: 'druid:bb123cd4567' OR 'bb123cd4567'
      # @param [String] content_metadata - contentMetadata.xml to be compared against a version of Moab
      # @param [String] subset - (default: 'all') which subset of files to compare (all|shelve|preserve|publish)
      # @param [String] version - version of Moab to be compared against (defaults to nil for latest version)
      # @return [Moab::FileInventoryDifference] differences of passed contentMetadata.xml
      #   with latest (or specified) version in Moab for all files (default) or
      #   a specified subset (shelve|preserve|publish)
      def content_inventory_diff(druid:, content_metadata:, subset: 'all', version: nil)
        result = post("objects/#{druid}/content_diff",
                      content_metadata: content_metadata, subset: subset, version: version)
        Moab::FileInventoryDifference.parse(result)
      end

      # convenience method for retrieving the differences in content files that should be "shelved" (altered in stacks)
      #   (or nil if no such differences)
      # @param [String] druid - with or without prefix: 'druid:bb123cd4567' OR 'bb123cd4567'
      # @param [String] content_metadata - most recent contentMetadata.xml to be compared against latest version of Moab
      # @return [Moab::FileGroupDifference] differences in content files that should be "shelved" (altered in stacks)
      #   (or nil if not found)
      def shelve_content_diff(druid:, content_metadata:)
        inventory_diff = content_inventory_diff(druid: druid, content_metadata: content_metadata, subset: 'shelve')
        inventory_diff.group_difference('content')
      end

      # @param [String] druid - with or without prefix: 'druid:ab123cd4567' OR 'ab123cd4567'
      # @return [Preservation::Client::Object] attributes of the Preserved Object
      def object(druid)
        resp_body = get_json("objects/#{druid}.json", druid)
        Object.new(**resp_body)
      end

      # @param [String] druid - with or without prefix: 'druid:ab123cd4567' OR 'ab123cd4567'
      # @return [Integer] the current version of the Preserved Object
      def current_version(druid)
        object(druid).current_version
      end

      # retrieve a content file from a Moab object
      # @param [String] druid - with or without prefix: 'druid:ab123cd4567' OR 'ab123cd4567'
      # @param [String] filepath - the path of the file relative to the moab content directory
      # @param [String] version - the version of the file requested (defaults to nil for latest version)
      # @param [Proc] on_data a block, if provided is called to do streaming responses
      def content(druid:, filepath:, version: nil, on_data: nil)
        file(druid, 'content', filepath, version, on_data: on_data)
      end

      # retrieve a content file from a Moab object and write it to destination atomically
      # @param [String] druid - with or without prefix: 'druid:ab123cd4567' OR 'ab123cd4567'
      # @param [String] filepath - the path of the file relative to the moab content directory
      # @param [String] destination_filepath - absolute or relative path to desired destination file
      # @param [String] version - the version of the file requested (defaults to nil for latest version)
      # @param [String, nil] expected_md5 - optional expected md5 checksum for integrity validation
      # @param [Integer] max - number of retry attempts after the initial attempt
      # @param [Float] interval - base delay in seconds for exponential retry backoff
      # @raise [Preservation::Client::IntegrityError] if the expected_md5 is provided and does not match the actual md5
      # @raise [Preservation::Client::NotFoundError] if the specified file is not found
      # @raise [Preservation::Client::Error] for other errors encountered during download
      def content_to_file(druid:, filepath:, destination_filepath:, version: nil, expected_md5: nil, # rubocop:disable Metrics/ParameterLists
                          max: nil, interval: nil)
        with_retries(max: max || @retry_max, interval: interval || @retry_interval) do
          temp_filepath = nil

          begin
            temp_filepath = download_to_tempfile(druid: druid, filepath: filepath,
                                                 destination_filepath: destination_filepath,
                                                 version: version)
            verify_md5!(filepath: temp_filepath, expected_md5: expected_md5) if expected_md5

            File.rename(temp_filepath, destination_filepath)
            temp_filepath = nil
          ensure
            cleanup_tempfile(temp_filepath)
          end
        end
      end

      # retrieve a manifest file from a Moab object
      # @param [String] druid - with or without prefix: 'druid:ab123cd4567' OR 'ab123cd4567'
      # @param [String] filepath - the path of the file relative to the moab manifest directory
      # @param [String] version - the version of the file requested (defaults to nil for latest version)
      def manifest(druid:, filepath:, version: nil)
        file(druid, 'manifest', filepath, version)
      end

      # retrieve a metadata file from a Moab object
      # @param [String] druid - with or without prefix: 'druid:ab123cd4567' OR 'ab123cd4567'
      # @param [String] filepath - the path of the file relative to the moab metadata directory
      # @param [String] version - the version of the file requested (defaults to nil for latest version)
      def metadata(druid:, filepath:, version: nil)
        file(druid, 'metadata', filepath, version)
      end

      # calls the endpoint to queue a ValidateMoab job for a specific druid
      # typically called by a preservationIngestWF robot
      # @param [String] druid - with or without prefix: 'druid:ab123cd4567' or 'ab123cd4567'
      # @return [String] "ok" when job queued
      # @raise [Preservation::Client::NotFoundError] when druid is not found
      def validate_moab(druid:)
        get("objects/#{druid}/validate_moab", {}, on_data: nil)
      end

      # convenience method for retrieving latest Moab::SignatureCatalog from a Moab object,
      # @param [String] druid - with or without prefix: 'druid:ab123cd4567' OR 'ab123cd4567'
      # @return [Moab::SignatureCatalog] the manifest of all files previously ingested
      def signature_catalog(druid)
        Moab::SignatureCatalog.parse manifest(druid: druid, filepath: 'signatureCatalog.xml')
      end

      private

      # get a file from a Moab object
      # @param [String] druid - with or without prefix: 'druid:ab123cd4567' OR 'ab123cd4567'
      # @param [String] category - one of 'manifest', 'metadata' or 'content'
      # @param [String] filepath - the path of the file relative to the moab category directory
      # @param [String] version - the version of the file requested
      # @param [Proc] on_data a block, if provided is called to do streaming responses
      # @return the retrieved file
      def file(druid, category, filepath, version, on_data: nil)
        get("objects/#{druid}/file", { category: category, filepath: filepath, version: version }, on_data: on_data)
      end

      def with_retries(max:, interval:)
        attempt = 0

        begin
          yield
        rescue StandardError => e
          raise if !retryable_error?(e) || attempt >= max

          sleep(interval.to_f * (Client::RETRY_BACKOFF_FACTOR**attempt))
          attempt += 1
          retry
        end
      end

      def download_to_tempfile(druid:, filepath:, destination_filepath:, version: nil)
        destination_dir = File.dirname(destination_filepath)
        FileUtils.mkdir_p(destination_dir)

        tempfile = Tempfile.create(['preservation-client-', '.tmp'], destination_dir)
        tempfile.binmode
        temp_filepath = tempfile.path

        begin
          content(druid: druid, filepath: filepath, version: version,
                  on_data: proc do |chunk, _size, _env|
                    tempfile.write(chunk)
                  end)
          tempfile.flush
          tempfile.fsync
        rescue StandardError
          cleanup_tempfile(temp_filepath)
          raise
        ensure
          tempfile.close
        end

        temp_filepath
      end

      def verify_md5!(filepath:, expected_md5:)
        actual_md5 = Digest::MD5.file(filepath).hexdigest
        return if actual_md5.casecmp?(expected_md5)

        raise IntegrityError,
              "Downloaded file md5 mismatch for #{filepath}: expected #{expected_md5}, got #{actual_md5}"
      end

      def retryable_error?(error)
        return true if error.is_a?(ConnectionFailedError)

        return true if error.is_a?(Error) && (500..599).cover?(error.status)

        false
      end

      def cleanup_tempfile(path)
        return if path.nil?
        return unless File.exist?(path)

        File.delete(path)
      rescue Errno::ENOENT
        nil
      end
    end
  end
end
