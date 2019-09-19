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

      def get_json(path, object_id, caller_method_name)
        resp = connection.get do |req|
          req.url api_version.present? ? "#{api_version}/#{path}" : path
          req.headers['Content-Type'] = 'application/json'
          req.headers['Accept'] = 'application/json'
        end
        return resp.body if resp.success?

        errmsg = ResponseErrorFormatter.format(response: resp, object_id: object_id, client_method_name: caller_method_name)
        raise Preservation::Client::UnexpectedResponseError, errmsg
      rescue Faraday::ResourceNotFound => e
        raise Preservation::Client::NotFoundError, "HTTP GET to #{connection.url_prefix}#{path} failed with #{e.class}: #{e.message}"
      rescue Faraday::ParsingError, Faraday::RetriableResponse => e
        raise Preservation::Client::UnexpectedResponseError, "HTTP GET to #{connection.url_prefix}#{path} failed with #{e.class}: #{e.message}"
      end
    end
  end
end
