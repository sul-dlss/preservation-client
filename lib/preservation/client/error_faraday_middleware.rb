# frozen_string_literal: true

module Preservation
  class Client
    # This wraps any faraday connection errors with preservation-client errors
    # see https://www.rubydoc.info/gems/faraday/Faraday/ClientError for info on errors
    class ErrorFaradayMiddleware < Faraday::Middleware
      def call(env)
        @app.call(env)
      rescue Faraday::ConnectionFailed, Faraday::SSLError, Faraday::TimeoutError => e
        raise ConnectionFailedError, "Unable to reach Preservation Catalog - failed with #{e.class}: #{e.message}"
      end
    end
  end
end
