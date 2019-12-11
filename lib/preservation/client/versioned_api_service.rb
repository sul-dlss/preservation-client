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
      def get_json(path, object_id)
        req_url = api_version.present? ? "#{api_version}/#{path}" : path
        resp = connection.get do |req|
          req.url req_url
          req.headers['Content-Type'] = 'application/json'
          req.headers['Accept'] = 'application/json'
        end
        return JSON.parse(resp.body).with_indifferent_access if resp.success?

        if resp.status == 404
          errmsg = "#{object_id} not found in Preservation at #{connection.url_prefix}#{req_url}"
          raise Preservation::Client::NotFoundError, errmsg
        else
          errmsg = ResponseErrorFormatter
                   .format(response: resp, object_id: object_id, client_method_name: caller_locations.first.label)
          raise Preservation::Client::UnexpectedResponseError, errmsg
        end
      rescue Faraday::ResourceNotFound => e
        errmsg = "HTTP GET to #{connection.url_prefix}#{req_url} failed with #{e.class}: #{e.message}"
        raise Preservation::Client::NotFoundError, errmsg
      rescue Faraday::ParsingError, Faraday::RetriableResponse => e
        errmsg = "HTTP GET to #{connection.url_prefix}#{req_url} failed with #{e.class}: #{e.message}"
        raise Preservation::Client::UnexpectedResponseError, errmsg
      end

      # @param path [String] path to be appended to connection url (no leading slash)
      # @param params [Hash] optional params
      def get(path, params)
        http_response(:get, path, params)
      end

      # @param path [String] path to be appended to connection url (no leading slash)
      # @param params [Hash] optional params
      def post(path, params)
        http_response(:post, path, params)
      end

      # @param method [Symbol] :get or :post
      # @param path [String] path to be appended to connection url (no leading slash)
      # @param params [Hash] optional params
      def http_response(method, path, params)
        req_path = api_version.present? ? "#{api_version}/#{path}" : path
        resp = connection.send(method, req_path, params)
        return resp.body if resp.success?

        errmsg = ResponseErrorFormatter.format(response: resp, client_method_name: caller_locations.first.label)
        raise Preservation::Client::UnexpectedResponseError, errmsg
      rescue Faraday::ResourceNotFound => e
        errmsg = "HTTP #{method.to_s.upcase} to #{connection.url_prefix}#{path} failed with #{e.class}: #{e.message}"
        raise Preservation::Client::NotFoundError, errmsg
      rescue Faraday::ParsingError, Faraday::RetriableResponse => e
        errmsg = "HTTP #{method.to_s.upcase} to #{connection.url_prefix}#{path} failed with #{e.class}: #{e.message}"
        raise Preservation::Client::UnexpectedResponseError, errmsg
      end
    end
  end
end
