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
        req_url = "#{api_version}/#{path}"
        resp = connection.get do |req|
          req.url req_url
          req.headers['Content-Type'] = 'application/json'
          req.headers['Accept'] = 'application/json'
        end
        return with_indifferent_access_for(JSON.parse(resp.body)) if resp.success?

        errmsg = ResponseErrorFormatter
                 .format(response: resp, object_id: object_id, client_method_name: caller_locations.first.label)
        raise UnexpectedResponseError, errmsg
      rescue Faraday::ResourceNotFound
        errmsg = "#{object_id} not found in Preservation at #{connection.url_prefix}#{req_url}"
        raise NotFoundError, errmsg
      rescue Faraday::Error => e
        errmsg = "Preservation::Client.#{caller_locations.first.label} for #{object_id} " \
                 "got #{e.response[:status]} from Preservation at #{req_url}: #{e.response[:body]}"
        raise UnexpectedResponseError, errmsg
      end

      # @param path [String] path to be appended to connection url (no leading slash)
      # @param params [Hash] optional request parameters
      # @param on_data [Proc] a callback to use when a streaming response is desired.
      def get(path, params, on_data:)
        return http_response(:get, path, params) unless on_data

        connection.get("#{api_version}/#{path}", params) do |req|
          req.options.on_data = on_data
        end
      end

      # @param path [String] path to be appended to connection url (no leading slash)
      # @param params [Hash] optional request parameters
      def post(path, params)
        http_response(:post, path, params)
      end

      # @param path [String] path to be appended to connection url (no leading slash)
      # @param params [Hash] optional request parameters
      def patch(path, params)
        http_response(:patch, path, params)
      end

      # @param path [String] path to be appended to connection url (no leading slash)
      # @param params [Hash] optional request parameters
      def put(path, params)
        http_response(:put, path, params)
      end

      # @param path [String] path to be appended to connection url (no leading slash)
      # @param params [Hash] optional request parameters
      def delete(path, params)
        http_response(:delete, path, params)
      end

      # @param method [Symbol] a symbol representing an HTTP method: :get, :post, :patch, :put, :delete
      # @param path [String] path to be appended to connection url (no leading slash)
      # @param params [Hash] optional request parameters
      def http_response(method, path, params)
        req_url = "#{api_version}/#{path}"
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
        raise UnexpectedResponseError, errmsg
      rescue Faraday::ResourceNotFound => e
        errmsg = "Preservation::Client.#{caller_locations.first.label} " \
                 "got #{e.response[:status]} from Preservation at #{req_url}: #{e.response[:body]}"
        raise NotFoundError, errmsg
      rescue Faraday::Error => e
        errmsg = "Preservation::Client.#{caller_locations.first.label} " \
                 "got #{e.response[:status]} from Preservation at #{req_url}: #{e.response[:body]}"
        raise http_exception_class(e.response[:status]), errmsg
      end

      # @param status_code [Integer] the HTTP status code to translate to an exception class
      def http_exception_class(status_code)
        case status_code
        when 423
          LockedError
        when 409
          ConflictError
        else
          UnexpectedResponseError
        end
      end

      def with_indifferent_access_for(obj)
        if obj.is_a?(Array)
          obj.map { |member| with_indifferent_access_for(member) }
        elsif obj.is_a?(Hash)
          obj.with_indifferent_access
        else
          obj
        end
      end
    end
  end
end
