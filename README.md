# NDR Pseudonymisation Service [![Build Status](https://github.com/publichealthengland/pseudonymisation_service/workflows/Test/badge.svg)](https://github.com/publichealthengland/pseudonymisation_service/actions?query=workflow%3Atest)

The `pseudonymisation_service` project is a Rails API-only application from PHE's National Disease Registration team that allows identifiers to be submitted, and pseudonymised versions to be returned.

## Usage

The easiest way to use the pseudonymisation service is through a `NdrPseudonymise::Client` object,
provided by the `ndr_pseudonymise` gem. This provides Ruby access to the three endpoints (described below, in "Endpoints").

## Basic Table Structure

Users can use pseudonymisation keys when a key grant has been given,
and any usage is then logged.

```
+------+      +----------+      +---------------------+
| User | ---> | KeyGrant | <--- | PseudonymisationKey |
+------+      +----------+      +---------------------+
     |                            |
     |        +----------+        |
     +------> | UsageLog | <------+
              +----------+
```

## Secrets Management

This project uses Rails' per-environment credentials API. Stored using are:
* pseudonymisation key secret salts
* per-environment identifier-logging encryption keys
* database credentials

For testing, the test environment credentials file and key file have been committed,
and can be viewed/updated using:

```
$ rails credentials:edit --environment test
```

To edit the credentials on the server (where the application user has read-only acces),
you need to do the following (as a `deployer`, who can write to the filesystem):

```
$ export PATH="~pseudo_live/.rbenv/bin:~pseudo_live/.rbenv/shims:${PATH}"
$ read -rsp '> ' RAILS_MASTER_KEY
$ export RAILS_MASTER_KEY
$ cd ~pseudo_live/pseudonymisation_service/current
$ RAILS_ENV=production bundle exec rails credentials:edit
```

To supply the unlock key to an ad-hoc production rake task, you can use the following:

```
$ RAILS_ENV=production rails credentials:unlock do:some:admin:task
```

## Authentication

Users are authenticated with tokens supplied in the request headers.
To set up a user, run:

```
$ rails users:create
```

A token can be (re)generated for a user using:

```
$ rails users:generate_token[the_username]
```

Users' key grants can be managed using the following tasks:

```
$ rails users:grants:list[the_username]
$ rails users:grants:add[the_username]
$ rails users:grants:revoke[the_username]
```

## Key Generation

To add new keys, first put salts into the `credentials.yml.enc`.
Note that the application must be restarted to reload the encrypted credentials.

Then, create `PseudonymistionKey` records from a Rails console:

```ruby
primary_key   = PseudonymisationKey.create!(name: 'primary_test_key')
secondary_key = PseudonymisationKey.create!(name: 'repseudo_test_key', parent_key: primary_key)

compound_key = PseudonymisationKey.create!(
  key_type: 'compound',
  name: 'compound_test_key',
  start_key: primary_key,
  end_key: secondary_key
)
```

Grants can then be done using the `users:grants:add` task.

## Endpoints

The service currently offers three endpoints, listed below.

### GET /keys

`GET` requests to `/keys` will return a JSON-encoded list of pseudonymisation keys availble to the current user.

```
curl -sH 'Authorization: Bearer user:token' site.dev/api/v1/keys
```
```json
[
  {
    "name": "test key1",
    "supported_variants": [
      1,
      2
    ]
  },
  {
    "name": "test key3",
    "supported_variants": [
      1,
      2
    ]
  }
]
```

### GET /variants

`GET` requests to `/variants` will return a JSON-encoded list of variants available to the current user, along with required identifier fields.

```
curl -sH 'Authorization: Bearer user:token' site.dev/api/v1/variants
```
```json
[
  {
    "variant": 1,
    "required_identifiers": [
      "nhs_number"
    ]
  },
  {
    "variant": 2,
    "required_identifiers": [
      "birth_date",
      "postcode"
    ]
  }
]
```

### POST /pseudonymise

`POST` requests to `/pseudonymise` will return JSON-encoded pseudonymised identifiers for supplied `"identifiers"`.
In addition, `"variants"` and `"key_names"` can be supplied, but if they are omitted sensible default choices are made.

```
curl -sH 'Authorization: Bearer user:token' \
     --header "Content-Type:application/json" \
     --data '{"identifiers":{"nhs_number":"1234567890"},"context":"README demo"}' \
     site.dev/api/v1/pseudonymise
```
```json
[
  {
    "key_name": "test key1",
    "variant": 1,
    "identifiers": {
      "nhs_number": "1234567890"
    },
    "context": "README demo",
    "pseudoid": "1e03fdf3..."
  },
  {
    "key_name": "test key3",
    "variant": 1,
    "identifiers": {
      "nhs_number": "1234567890"
    },
    "context": "README demo",
    "pseudoid": "8cc142ecb..."
  }
]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies, set up a database, and start a web server. You'll need to have PostgreSQL installed already.

Tests can be run with `bin/rake`.

## Contributing

1. Fork it ( https://github.com/publichealthengland/pseudonymisation_service/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Please note that this project is released with a Contributor Code of Conduct. By participating in this project you agree to abide by its terms.
