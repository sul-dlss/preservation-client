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
        return post('catalog', http_args) if version == 1

        patch("catalog/#{druid}", http_args)
      end
    end
  end
end
