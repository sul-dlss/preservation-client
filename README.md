[![Gem Version](https://badge.fury.io/rb/preservaton-client.svg)](https://badge.fury.io/rb/preservation-client)
[![Build Status](https://travis-ci.org/sul-dlss/preservation-client.svg?branch=master)](https://travis-ci.org/sul-dlss/preservation-client)
[![Maintainability](https://api.codeclimate.com/v1/badges/00d2d8957226777105b3/maintainability)](https://codeclimate.com/github/sul-dlss/preservation-client/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/00d2d8957226777105b3/test_coverage)](https://codeclimate.com/github/sul-dlss/preservation-client/test_coverage)
[![Coverage Status](https://coveralls.io/repos/github/sul-dlss/preservation-client/badge.svg)](https://coveralls.io/github/sul-dlss/preservation-client)

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
require 'preservation/client'

def do_the_thing
  # This API endpoint returns an integer
  current_version_as_integer = client.current_version(params: { druid: 'druid:123' })
end

private

def client
  @client ||= Preservation::Client.configure(url: Settings.preservation_catalog.url)
end
```

Note that the client may **not** be used without first having been configured, and the `url` keyword is **required**.

Note that the preservation service is behind a firewall.

## API Coverage

- Preservation::Client.objects.current_version('oo000oo0000')  (can also be 'druid:oo000oo0000')
- Preservation::Client.objects.checksums(druids: druids) - will return raw csv
- Preservation::Client.objects.checksums(druids: druids, format: 'json') - will return json

## Development

After checking out the repo, run `bundle` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `lib/preservation/client/version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sul-dlss/preservation-client

## Copyright

Copyright (c) 2019 Stanford Libraries. See LICENSE for details.
