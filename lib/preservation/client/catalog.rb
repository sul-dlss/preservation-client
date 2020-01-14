# frozen_string_literal: true

module Preservation
  class Client
    # API calls that are about the catalog
    class Catalog < VersionedApiService
      # @param [String] druid the object identifierx
      # @param [Integer] version the version of the object
      # @param [Integer] size the size of the object
      # @param [String] storage_location the location of storage
      def update(druid:, version:, size:, storage_location:)
        http_args = {
          druid: druid,
          incoming_version: version,
          incoming_size: size,
          storage_location: storage_location,
          checksums_validated: true
        }

        request(druid: druid, version: version, http_args: http_args)
      end

      private

      def request(druid:, version:, http_args:)
        result = if version == 1
                   connection.post "/#{api_version}/catalog", http_args
                 else
                   connection.patch "/#{api_version}/catalog/#{druid}", http_args
                 end
        unless result.success?
          raise UnexpectedResponseError, "response was not successful. Received status #{result.status}"
        end

        true
      rescue Faraday::Error => e
        raise UnexpectedResponseError, e
      end
    end
  end
end
