# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'preservation/client/version'

Gem::Specification.new do |spec|
  spec.name          = 'preservation-client'
  spec.version       = Preservation::Client::VERSION
  spec.authors       = ['Naomi Dushay']
  spec.email         = ['ndushay@stanford.edu']

  spec.summary       = 'A thin client for getting info from SDR preservation.'
  spec.description   = 'A Ruby client for the RESTful HTTP APIs provided by the Preservation Catalog API.'
  spec.homepage      = 'https://github.com/sul-dlss/preservation-client'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org/'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/sul-dlss/preservation-client.'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '>= 4.2', '< 7'
  spec.add_dependency 'faraday', '>= 0.15', '< 2.0'
  spec.add_dependency 'moab-versioning', '~> 4.3'
  spec.add_dependency 'zeitwerk', '~> 2.1'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.77.0'
  spec.add_development_dependency 'simplecov', '~> 0.17.0' # For CodeClimate
  spec.add_development_dependency 'webmock'
end
