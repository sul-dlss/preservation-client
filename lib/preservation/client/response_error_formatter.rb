# frozen_string_literal: true

module Preservation
  class Client
    # Format HTTP response-related errors
    class ResponseErrorFormatter
      DEFAULT_BODY = 'Response from preservation-catalog did not contain a body. '\
                     'Check honeybadger for preservation-catalog for backtraces, '\
                     'and look into adding a `rescue_from` in preservation-catalog '\
                     'to provide more details to the client in the future.'

      def self.format(response:, object_id: nil, client_method_name: nil)
        new(response: response, object_id: object_id, client_method_name: client_method_name).format
      end

      attr_reader :req_url, :status_msg, :status_code, :body, :object_id, :client_method_name

      def initialize(response:, object_id: nil, client_method_name: nil)
        @req_url = response.env.url
        @status_msg = response.reason_phrase
        @status_code = response.status
        @body = response.body.present? ? response.body : DEFAULT_BODY
        @object_id = object_id
        @client_method_name = client_method_name
      end

      def format
        status_info = status_msg.blank? ? status_code : "#{status_msg} (#{status_code})"
        object_id_info = " for #{object_id}" if object_id.present?

        "Preservation::Client.#{client_method_name}#{object_id_info} got #{status_info} from Preservation Catalog at #{req_url}: #{body}"
      end
    end
  end
end
