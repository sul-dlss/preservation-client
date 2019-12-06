[![Gem Version](https://badge.fury.io/rb/preservation-client.svg)](https://badge.fury.io/rb/preservation-client)
[![Build Status](https://travis-ci.org/sul-dlss/preservation-client.svg?branch=master)](https://travis-ci.org/sul-dlss/preservation-client)
[![Maintainability](https://api.codeclimate.com/v1/badges/00d2d8957226777105b3/maintainability)](https://codeclimate.com/github/sul-dlss/preservation-client/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/00d2d8957226777105b3/test_coverage)](https://codeclimate.com/github/sul-dlss/preservation-client/test_coverage)

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

### Get the current version of a preserved object (Moab)

- Preservation::Client.objects.current_version('oo000oo0000')  (can also be 'druid:oo000oo0000')

### Retrieve file signature (checksum) information

- Preservation::Client.objects.checksums(druids: druids) - returns info as raw csv
- Preservation::Client.objects.checksums(druids: druids, format: 'json') - returns info as json

### Retrieve individual files from preservation

- Preservation::Client.objects.content(druid: 'oo000oo0000', filepath: 'my_file.pdf') - returns contents of my_file.pdf in most recent version of Moab object
- Preservation::Client.objects.content(druid: 'oo000oo0000', filepath: 'my_file.pdf', version: '1') - returns contents of my_file.pdf in version 1 of Moab object
- Preservation::Client.objects.manifest(druid: 'oo000oo0000', filepath: 'versionInventory.xml') - returns contents of versionInventory.xml in most recent version of Moab object
- Preservation::Client.objects.manifest(druid: 'oo000oo0000', filepath: 'versionInventory.xml', version: '3') - returns contents of versionInventory.xml in version 3 of Moab object
- Preservation::Client.objects.metadata(druid: 'oo000oo0000', filepath: 'identityMetadata.xml') - returns contents of identityMetadata.xml in most recent version of Moab object
- Preservation::Client.objects.metadata(druid: 'oo000oo0000', filepath: 'identityMetadata.xml', version: '8') - returns contents of identityMetadata.xml in version 8 of Moab object
- Preservation::Client.objects.signature_catalog(druid: 'oo000oo0000') - returns contents of latest version of signatureCatalog.xml from Moab object

### Get difference information between passed contentMetadata.xml and files in the Moab

- Preservation::Client.objects.content_inventory_diff(druid: 'oo000oo0000', content_metadata: '<contentMetadata>...</contentMetadata>') - returns Moab::FileInventoryDifference containing differences between passed content metadata and latest version for subset 'all' (all|shelve|preserve|publish)
  - you can also specify the subset and/or the version:
    - Preservation::Client.objects.content_inventory_diff(druid: 'oo000oo0000', subset: 'publish', version: '1', content_metadata: '<contentMetadata>...</contentMetadata>')

- Preservation::Client.objects.shelve_content_diff(druid: 'oo000oo0000', content_metadata: '<contentMetadata>...</contentMetadata>') - returns Moab::FileGroupDifference containing differences between passed content metadata and latest version for subset 'shelve'

## Development

After checking out the repo, run `bundle` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `lib/preservation/client/version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sul-dlss/preservation-client

## Copyright

Copyright (c) 2019 Stanford Libraries. See LICENSE for details.
