# frozen_string_literal: true

module Preservation
  class Client
    # API calls that are about Preserved Objects
    class Objects < VersionedService
      # @param [String] druid - with or without prefix: 'druid:ab123cd4567' OR 'ab123cd4567'
      # @return [Integer] the current version of the Preserved Object
      def current_version(druid)
        resp = get_json("objects/#{druid}.json", 'current_version')
        json = JSON.parse(resp.body).with_indifferent_access
        json[:current_version]
      end

      private

      def get_json(path, method_name)
        resp = connection.get do |req|
          req.url = api_version.present? ? "#{api_version}/#{path}" : path
          req.headers['Content-Type'] = 'application/json'
          req.headers['Accept'] = 'application/json'
        end
        return resp.body if resp.success?

        errmsg = ResponseErrorFormatter.format(response: resp, object_id: druid, client_method_name: method_name)
        raise UnexpectedResponse, errmsg
      rescue Faraday::NotFoundResponse => e
        raise NotFoundError, "HTTP GET to #{url}/#{path} failed with #{e.class}: #{e.message}"
      rescue Faraday::ParsingError, Faraday::RetriableResponse => e
        raise UnexpectedResponse, "HTTP GET to #{url}/#{path} failed with #{e.class}: #{e.message}"
      end
    end
  end
end
