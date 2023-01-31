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

    # Error raised when server returns 404 Not Found
    class NotFoundError < Error; end

    # Error raised when server returns 423 Locked
    class LockedError < Error; end

    # Error raised when server returns an unexpected response
    # e.g., 4xx or 5xx status not otherwise handled
    class UnexpectedResponseError < Error; end

    # Error raised when Faraday gem fails to connect, e.g., on SSL errors or
    # timeouts
    class ConnectionFailedError < Error; end

    DEFAULT_API_VERSION = 'v1'
    DEFAULT_TIMEOUT = 300
    TOKEN_HEADER = 'Authorization'

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
      # @param [String] url the endpoint URL
      # @param [String] token a bearer token for HTTP authentication
      # @param [Integer] read_timeout the value in seconds of the read timeout
      def configure(url:, token:, read_timeout: DEFAULT_TIMEOUT)
        instance.url = url
        instance.token = token
        instance.read_timeout = read_timeout

        # Force connection to be re-established when `.configure` is called
        instance.connection = nil

        self
      end

      delegate :objects, :update, to: :instance
    end

    attr_writer :connection, :read_timeout, :token, :url

    delegate :update, to: :catalog

    private

    def url
      @url || raise(Error, 'url has not yet been configured')
    end

    def token
      @token || raise(Error, 'auth token has not been configured')
    end

    def read_timeout
      @read_timeout || raise(Error, 'read timeout has not been configured')
    end

    def connection
      @connection ||= Faraday.new(url, request: { read_timeout: read_timeout }) do |builder|
        builder.use ErrorFaradayMiddleware
        builder.use Faraday::Request::UrlEncoded
        builder.use Faraday::Response::RaiseError # raise exceptions on 40x, 50x responses
        builder.adapter Faraday.default_adapter
        builder.headers[:user_agent] = user_agent
        builder.headers[TOKEN_HEADER] = "Bearer #{token}"
      end
    end

    def user_agent
      "preservation-client #{Preservation::Client::VERSION}"
    end
  end
end
