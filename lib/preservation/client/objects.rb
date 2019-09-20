# frozen_string_literal: true

module Preservation
  class Client
    # API calls that are about Preserved Objects
    class Objects < VersionedService

      # @param [String] druid - with or without prefix: 'druid:ab123cd4567' OR 'ab123cd4567'
      # @return [Integer] the current version of the Preserved Object
      def current_version(druid)
        resp_body = get_json("objects/#{druid}.json", druid, 'current_version')
        resp_body[:current_version]
      end
    end
  end
end
