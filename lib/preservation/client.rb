# frozen_string_literal: true

require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'
require 'faraday'
require 'singleton'
require 'zeitwerk'

loader = Zeitwerk::Loader.new
loader.inflector = Zeitwerk::GemInflector.new(__FILE__)
loader.push_dir(File.absolute_path("#{__FILE__}/../.."))
loader.setup

module Preservation
  # REST API client wrapper for PreservationCatalog with error handling
  class Client
    class Error < StandardError; end

    # Error that is raised when the remote server returns a 404 Not Found
    class NotFoundError < Error; end

    # Error that is raised when the remote server returns some unexpected response
    # e.g. 4xx or 5xx status
    class UnexpectedResponseError < Error; end

    class ConnectionFailedError < Error; end

    DEFAULT_API_VERSION = 'v1'

    include Singleton

    # @return [Preservation::Client::Objects] an instance of the `Client::Objects` class
    def objects
      @objects ||= Objects.new(connection: connection, api_version: DEFAULT_API_VERSION)
    end

    # @return [Preservation::Client::Catalog] an instance of the `Client::Catalog` class
    def catalog
      @catalog ||= Catalog.new(connection: connection, api_version: DEFAULT_API_VERSION)
    end

    class << self
      # @param [String] url
      def configure(url:)
        instance.url = url

        # Force connection to be re-established when `.configure` is called
        instance.connection = nil

        self
      end

      delegate :objects, :update, to: :instance
    end

    attr_writer :url, :connection
    delegate :update, to: :catalog

    private

    def url
      @url || raise(Error, 'url has not yet been configured')
    end

    def connection
      @connection ||= Faraday.new(url) do |builder|
        builder.use ErrorFaradayMiddleware
        builder.use Faraday::Request::UrlEncoded
        builder.use Faraday::Response::RaiseError # raise exceptions on 40x, 50x responses
        builder.adapter Faraday.default_adapter
        builder.headers[:user_agent] = user_agent
      end
    end

    def user_agent
      "preservation-client #{Preservation::Client::VERSION}"
    end
  end
end
