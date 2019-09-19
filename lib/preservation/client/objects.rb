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
    end
  end
end
