# frozen_string_literal: true

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
      def content(druid:, filepath:, version: nil)
        file(druid, 'content', filepath, version)
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

      # convenience method for retrieving latest signatureCatalog.xml file from a Moab object
      # @param [String] druid - with or without prefix: 'druid:ab123cd4567' OR 'ab123cd4567'
      def signature_catalog(druid)
        manifest(druid: druid, filepath: 'signatureCatalog.xml')
      end

      private

      # get a file from a Moab object
      # @param [String] druid - with or without prefix: 'druid:ab123cd4567' OR 'ab123cd4567'
      # @param [String] category - one of 'manifest', 'metadata' or 'content'
      # @param [String] filepath - the path of the file relative to the moab category directory
      # @param [String] version - the version of the file requested (defaults to nil for latest version)
      # @return the retrieved file
      def file(druid, category, filepath, version = nil)
        get("objects/#{druid}/file", category: category, filepath: filepath, version: version)
      end
    end
  end
end
