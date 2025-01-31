[![Gem Version](https://badge.fury.io/rb/preservation-client.svg)](https://badge.fury.io/rb/preservation-client)
[![CircleCI](https://circleci.com/gh/sul-dlss/preservation-client.svg?style=svg)](https://circleci.com/gh/sul-dlss/preservation-client)
[![codecov](https://codecov.io/github/sul-dlss/preservation-client/graph/badge.svg?token=1499MH27Z6)](https://codecov.io/github/sul-dlss/preservation-client)

# preservation-client

preservation-client is a Ruby gem that acts as a client to the RESTful HTTP APIs provided by [preservation_catalog](https://github.com/sul-dlss/preservation_catalog).

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

Preservation::Client is a singleton object, and thus can be used as a class or an instance.

```ruby
require 'preservation/client'

def do_the_thing
  current_version_as_integer = client.objects.current_version('druid:oo000oo0000')
end

private

def client
  @client ||= Preservation::Client.configure(url: Settings.preservation_catalog.url, token: Settings.preservation_catalog.token)
end
```

OR

```ruby
require 'preservation/client'

def initialize
  Preservation::Client.configure(url: Settings.preservation_catalog.url, token: Settings.preservation_catalog.token)
end

def do_the_thing
  current_version_as_integer = Preservation::Client.objects.current_version('druid:oo000oo0000')
end
```

Note that the client may **not** be used without first having been configured, and both the `url` and `token` keywords are **required**.

See https://github.com/sul-dlss/preservation_catalog#api for info on obtaining a valid API token.

Note that the preservation service is behind a firewall.

## API Coverage

- druids may be with or without the "druid:" prefix - 'oo000oo0000' or 'druid:oo000oo0000'
- methods can be called as `client_instance.objects.method` or `Preservation::Client.objects.method`

### Get the current version of a preserved object (Moab)

- `client.objects.current_version('oo000oo0000')` - returns latest version as an Integer

### Retrieve file signature (checksum) information

- `client.objects.checksum(druid: 'oo000oo0000')` - returns info as array of hashes

### Retrieve individual files from preservation

- `client.objects.content(druid: 'oo000oo0000', filepath: 'my_file.pdf')` - returns contents of my_file.pdf in most recent version of Moab object
  - You may specify the version:
    - `client.objects.content(druid: 'oo000oo0000', filepath: 'my_file.pdf', version: '1')` - returns contents of my_file.pdf in version 1 of Moab object
- `client.objects.manifest(druid: 'oo000oo0000', filepath: 'versionInventory.xml')` - returns contents of versionInventory.xml in most recent version of Moab object
  - You may specify the version:
    - `client.objects.manifest(druid: 'oo000oo0000', filepath: 'versionInventory.xml', version: '3')` - returns contents of versionInventory.xml in version 3 of Moab object
- `client.objects.metadata(druid: 'oo000oo0000', filepath: 'identityMetadata.xml')` - returns contents of identityMetadata.xml in most recent version of Moab object
  - You may specify the version:
    - `client.objects.metadata(druid: 'oo000oo0000', filepath: 'identityMetadata.xml', version: '8')` - returns contents of identityMetadata.xml in version 8 of Moab object
- `client.objects.signature_catalog('oo000oo0000')` - returns latest Moab::SignatureCatalog from Moab

### Validate the Moab

- `client.objects.validate_moab(druid: 'ooo000oo0000')` - validates that the Moab object, used by preservationWF to ensure we have a valid Moab before replicating to various preservation endpoints

### Get difference information between passed contentMetadata.xml and files in the Moab

- `client.objects.content_inventory_diff(druid: 'oo000oo0000', content_metadata: '<contentMetadata>...</contentMetadata>')` - returns Moab::FileInventoryDifference containing differences between passed content metadata and latest version for subset 'all'

  - you may specify the subset (all|shelve|preserve|publish) and/or the version:
    - `client.objects.content_inventory_diff(druid: 'oo000oo0000', subset: 'publish', version: '1', content_metadata: '<contentMetadata>...</contentMetadata>')`

- `client.objects.shelve_content_diff(druid: 'oo000oo0000', content_metadata: '<contentMetadata>...</contentMetadata>')` - returns Moab::FileGroupDifference containing differences between passed content metadata and latest version for subset 'shelve'

### Alert the catalog that an object has been changed and needs to be updated

- `client.update(druid: 'oo000oo0000', version: 3, size: 2342, storage_location: 'some/storage/location')` - returns true if it worked

## Development

After checking out the repo, run `bundle` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `lib/preservation/client/version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sul-dlss/preservation-client

## Copyright

Copyright (c) 2019 Stanford Libraries. See LICENSE for details.
