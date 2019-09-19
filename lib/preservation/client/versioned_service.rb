# frozen_string_literal: true

module Preservation
  class Client
    # @abstract API calls to a versioned endpoint
    class VersionedService
      def initialize(connection:, api_version:)
        @connection = connection
        @api_version = api_version
      end

      private

      attr_reader :connection, :api_version
    end
  end
end
