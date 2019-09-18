[![Gem Version](https://badge.fury.io/rb/preservaton-client.svg)](https://badge.fury.io/rb/preservation-client)
[![Build Status](https://travis-ci.com/sul-dlss/preservation-client.svg?branch=master)](https://travis-ci.com/sul-dlss/preservation-client)
[![Code Climate](https://codeclimate.com/github/sul-dlss/preservation-client/badges/gpa.svg)](https://codeclimate.com/github/sul-dlss/preservation-client)
[![Code Climate Test Coverage](https://codeclimate.com/github/sul-dlss/preservation/badges/coverage.svg)](https://codeclimate.com/github/sul-dlss/preservation-client/coverage)

# Preservation::Client

Preservation::Client is a Ruby gem that acts as a client to the RESTful HTTP APIs provided by [preservation_catalog](https://github.com/sul-dlss/preservation_catalog).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'preservation-client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install preservation-client

## Usage

To configure and use the client, here's an example:

```ruby
require 'dor/services/client'

def do_the_thing
  # This API endpoint returns an integer
  current_version_as_integer = client.current_version(params: { druid: 'druid:123' })
end

private

def client
  @client ||= Preservation::Client.configure(url: Settings.dor_services.url)
end
```

Note that the client may **not** be used without first having been configured, and the `url` keyword is **required**.

Note that the preservation service is behind a firewall.

## API Coverage

TBD

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sul-dlss/preservation-client

## Copyright

Copyright (c) 2019 Stanford Libraries. See LICENSE for details.
