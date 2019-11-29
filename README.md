# README

The `pseudonymisation_service` project is a Rails API-only application that allows demographics to be submitted, and pseudonymised versions to be returned.

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
* per-environment demographic-logging encryption keys
* database credentials

For testing, the test environment credentials file and key file have been committed,
and can be viewed/updated using:

```
$ rails credentials:edit --environment test
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
