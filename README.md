# README

The `pseudonymisation_service` project is a Rails API-only application that allows identifiers to be submitted, and pseudonymised versions to be returned.

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

### GET /variants

`GET` requests to `/variants` will return a JSON-encoded list of variants available to the current user, along with required identifier fields.

### POST /pseudonymise

`POST` requests to `/pseudonymise` will return JSON-encoded pseudonymised identifiers for supplied `"identifiers"`.
In addition, `"variants"` and `"key_names"` can be supplied, but if they are omitted sensible default choices are made.
