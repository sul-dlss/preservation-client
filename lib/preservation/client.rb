# frozen_string_literal: true

require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'
require 'faraday'
require 'faraday/retry'
require 'singleton'
require 'zeitwerk'

loader = Zeitwerk::Loader.new
loader.inflector = Zeitwerk::GemInflector.new(__FILE__)
loader.push_dir(File.absolute_path("#{__FILE__}/../.."))
loader.setup

module Preservation
  # REST API client wrapper for PreservationCatalog with error handling
  class Client
    # Base error class for preservation-client errors
    class Error < StandardError
      attr_reader :status

      def initialize(message = nil, status: nil)
        super(message)
        @status = status
      end
    end

    # Error raised when server returns 404 Not Found
    class NotFoundError < Error; end

    # Error raised when server returns 423 Locked
    class LockedError < Error; end

    # Error raised when server returns 409 Conflict
    class ConflictError < Error; end

    # Error raised when server returns an unexpected response
    # e.g., 4xx or 5xx status not otherwise handled
    class UnexpectedResponseError < Error; end

    # Error raised when Faraday gem fails to connect, e.g., on SSL errors or
    # timeouts
    class ConnectionFailedError < Error; end

    # Error raised when downloaded file integrity verification fails
    class IntegrityError < Error; end

    Object = Struct.new('Object', :druid, :current_version, :ok_on_local_storage) do
      def ok_on_local_storage?
        ok_on_local_storage
      end
    end

    DEFAULT_API_VERSION = 'v1'
    DEFAULT_TIMEOUT = 300
    DEFAULT_RETRY_MAX = 3
    DEFAULT_RETRY_INTERVAL = 0.5
    RETRY_BACKOFF_FACTOR = 2
    TOKEN_HEADER = 'Authorization'

    include Singleton

    # @return [Preservation::Client::Objects] an instance of the `Client::Objects` class
    def objects
      @objects ||= Objects.new(connection: connection, streaming_connection: streaming_connection,
                               retry_max: retry_max, retry_interval: retry_interval,
                               api_version: DEFAULT_API_VERSION)
    end

    # @return [Preservation::Client::Catalog] an instance of the `Client::Catalog` class
    def catalog
      @catalog ||= Catalog.new(connection: connection, api_version: DEFAULT_API_VERSION)
    end

    class << self
      # @param [String] url the endpoint URL
      # @param [String] token a bearer token for HTTP authentication
      # @param [Integer] read_timeout the value in seconds of the read timeout
      # @param [Integer] retry_max number of retry attempts for GET requests
      # @param [Float] retry_interval base delay in seconds between retries (exponential backoff)
      def configure(url:, token:, read_timeout: DEFAULT_TIMEOUT,
                    retry_max: DEFAULT_RETRY_MAX, retry_interval: DEFAULT_RETRY_INTERVAL)
        instance.url = url
        instance.token = token
        instance.read_timeout = read_timeout
        instance.retry_max = retry_max
        instance.retry_interval = retry_interval

        # Force connections to be re-established when `.configure` is called
        instance.connection = nil
        instance.streaming_connection = nil

        self
      end

      delegate :objects, :update, to: :instance
    end

    attr_writer :connection, :read_timeout, :retry_interval, :retry_max, :streaming_connection, :token, :url

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

    def retry_max
      @retry_max || raise(Error, 'retry_max has not been configured')
    end

    def retry_interval
      @retry_interval || raise(Error, 'retry_interval has not been configured')
    end

    def connection
      @connection ||= build_connection(with_retry: true)
    end

    def streaming_connection
      @streaming_connection ||= build_connection(with_retry: false)
    end

    def build_connection(with_retry: true) # rubocop:disable Metrics/AbcSize
      Faraday.new(url, request: { read_timeout: read_timeout }) do |builder|
        builder.use ErrorFaradayMiddleware
        if with_retry
          builder.request :retry, max: retry_max,
                                  interval: retry_interval,
                                  backoff_factor: RETRY_BACKOFF_FACTOR,
                                  methods: [:get],
                                  exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS +
                                              [Faraday::ConnectionFailed, Faraday::SSLError, Faraday::ServerError]
        end
        builder.use Faraday::Request::UrlEncoded
        builder.use Faraday::Response::RaiseError
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
