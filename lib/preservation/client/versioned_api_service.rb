# frozen_string_literal: true

module Preservation
  class Client
    # @abstract API calls to a versioned endpoint
    class VersionedApiService
      def initialize(connection:, api_version:)
        @connection = connection
        @api_version = api_version
      end

      private

      attr_reader :connection, :api_version

      # @param path [String] path to be appended to connection url (no leading slash)
      def get_json(path, object_id, caller_method_name)
        resp = connection.get do |req|
          req.url api_version.present? ? "#{api_version}/#{path}" : path
          req.headers['Content-Type'] = 'application/json'
          req.headers['Accept'] = 'application/json'
        end
        return JSON.parse(resp.body).with_indifferent_access if resp.success?

        errmsg = ResponseErrorFormatter
                 .format(response: resp, object_id: object_id, client_method_name: caller_method_name)
        raise Preservation::Client::UnexpectedResponseError, errmsg
      rescue Faraday::ResourceNotFound => e
        errmsg = "HTTP GET to #{connection.url_prefix}#{path} failed with #{e.class}: #{e.message}"
        raise Preservation::Client::NotFoundError, errmsg
      rescue Faraday::ParsingError, Faraday::RetriableResponse => e
        errmsg = "HTTP GET to #{connection.url_prefix}#{path} failed with #{e.class}: #{e.message}"
        raise Preservation::Client::UnexpectedResponseError, errmsg
      end

      # @param path [String] path to be appended to connection url (no leading slash)
      # @param params [Hash] optional params
      def post(path, params, caller_method_name)
        post_path = api_version.present? ? "#{api_version}/#{path}" : path
        resp = connection.post post_path, params
        return resp.body if resp.success?

        errmsg = ResponseErrorFormatter
                 .format(response: resp, client_method_name: caller_method_name)
        raise Preservation::Client::UnexpectedResponseError, errmsg
      rescue Faraday::ResourceNotFound => e
        errmsg = "HTTP POST to #{connection.url_prefix}#{path} failed with #{e.class}: #{e.message}"
        raise Preservation::Client::NotFoundError, errmsg
      rescue Faraday::ParsingError, Faraday::RetriableResponse => e
        errmsg = "HTTP POST to #{connection.url_prefix}#{path} failed with #{e.class}: #{e.message}"
        raise Preservation::Client::UnexpectedResponseError, errmsg
      end
    end
  end
end
