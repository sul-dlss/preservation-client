# frozen_string_literal: true

module Preservation
  class Client
    # @abstract API calls to a versioned endpoint
    class VersionedApiService
      def initialize(connection:, api_version: DEFAULT_API_VERSION)
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

        errmsg = ResponseErrorFormatter
                 .format(response: resp, object_id: object_id, client_method_name: caller_locations.first.label)
        raise Preservation::Client::UnexpectedResponseError, errmsg
      rescue Faraday::ResourceNotFound
        errmsg = "#{object_id} not found in Preservation at #{connection.url_prefix}#{req_url}"
        raise Preservation::Client::NotFoundError, errmsg
      rescue Faraday::Error => e
        errmsg = "Preservation::Client.#{caller_locations.first.label} for #{object_id} " \
          "got #{e.response[:status]} from Preservation at #{req_url}: #{e.response[:body]}"
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

      # @param path [String] path to be appended to connection url (no leading slash)
      # @param params [Hash] optional params
      def patch(path, params)
        http_response(:patch, path, params)
      end

      # @param path [String] path to be appended to connection url (no leading slash)
      # @param params [Hash] optional params
      def put(path, params)
        http_response(:put, path, params)
      end

      # @param path [String] path to be appended to connection url (no leading slash)
      # @param params [Hash] optional params
      def delete(path, params)
        http_response(:delete, path, params)
      end

      # @param method [Symbol] a symbol representing an HTTP method: :get, :post, :patch, :put, :delete
      # @param path [String] path to be appended to connection url (no leading slash)
      # @param params [Hash] optional params
      def http_response(method, path, params)
        req_url = api_version.present? ? "#{api_version}/#{path}" : path
        resp =
          case method
          when :delete, :get
            connection.public_send(method, req_url, params)
          when :patch, :post, :put
            request_json = params.to_json if params&.any?
            connection.public_send(method, req_url, request_json, 'Content-Type' => 'application/json')
          end
        return resp.body if resp.success?

        errmsg = ResponseErrorFormatter.format(response: resp, client_method_name: caller_locations.first.label)
        raise Preservation::Client::UnexpectedResponseError, errmsg
      rescue Faraday::ResourceNotFound => e
        errmsg = "Preservation::Client.#{caller_locations.first.label} " \
          "got #{e.response[:status]} from Preservation at #{req_url}: #{e.response[:body]}"
        raise Preservation::Client::NotFoundError, errmsg
      rescue Faraday::Error => e
        errmsg = "Preservation::Client.#{caller_locations.first.label} " \
          "got #{e.response[:status]} from Preservation at #{req_url}: #{e.response[:body]}"
        raise Preservation::Client::UnexpectedResponseError, errmsg
      end
    end
  end
end
