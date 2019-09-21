# frozen_string_literal: true

module Preservation
  class Client
    # API calls that are about Preserved Objects
    class Objects < VersionedApiService

      # @param [String] druid - with or without prefix: 'druid:ab123cd4567' OR 'ab123cd4567'
      # @return [Integer] the current version of the Preserved Object
      def current_version(druid)
        resp_body = get_json("objects/#{druid}.json", druid, 'current_version')
        resp_body[:current_version]
      end

      # @param [Array] druids - required list of druids with or without prefix: 'druid:ab123cd4567' OR 'ab123cd4567'
      # @param [String] :resp_format - desired format of the HTTP response (default csv, json also possible)
      # @return body of HTTP response from Preservation API
      def checksums(druids: [], resp_format: 'csv')
        post('objects/checksums', { druids: druids, format: resp_format }, 'checksums')
      end
    end
  end
end
