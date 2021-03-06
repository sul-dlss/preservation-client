# frozen_string_literal: true

require 'moab'

# NOTE:  this class makes use of data structures from moab-versioning gem,
#  but it does NOT directly access any preservation storage roots
module Preservation
  class Client
    # API calls that are about Preserved Objects
    class Objects < VersionedApiService
      # @param [Array] druids - required list of druids with or without prefix: 'druid:ab123cd4567' OR 'ab123cd4567'
      # @param [String] resp_format - desired format of the HTTP response (default csv, json also possible)
      # @return body of HTTP response from Preservation API - the checksums and filesize for each druid
      def checksums(druids: [], resp_format: 'csv')
        post('objects/checksums', druids: druids, format: resp_format)
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
      # @return [Integer] the current version of the Preserved Object
      def current_version(druid)
        resp_body = get_json("objects/#{druid}.json", druid)
        resp_body[:current_version]
      end

      # retrieve a content file from a Moab object
      # @param [String] druid - with or without prefix: 'druid:ab123cd4567' OR 'ab123cd4567'
      # @param [String] filepath - the path of the file relative to the moab content directory
      # @param [String] version - the version of the file requested (defaults to nil for latest version)
      # @param [Proc] on_data a block, if provided is called to do streaming responses
      def content(druid:, filepath:, version: nil, on_data: nil)
        file(druid, 'content', filepath, version, on_data: on_data)
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

      # retrieve the storage location for the primary moab of the given druid
      # @param [String] druid - with or without prefix: 'druid:ab123cd4567' or 'ab123cd4567'
      # @return [String] the storage location of the primary moab for the given druid
      # @raise [Preservation::Client::NotFoundError] when druid is not found
      # @raise [Preservation::Client::LockedError] when druid is in locked state (not available for versioning)
      def primary_moab_location(druid:)
        get("objects/#{druid}/primary_moab_location", {}, on_data: nil)
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
    end
  end
end
