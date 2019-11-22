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

## Authentication

Users are authenticated with tokens supplied in the request headers.
To set up a user, run:

```
$ rails users:create
```

A token can be (re)generated for a user using:

```
$ rails users:generate_token
```

## TODO

* use per-env secrets, as per Rails 6 convention
* Implement public key encryption of `UsageLog` demographics.
* Add rake tasks for `PseudonymisationKey` and `KeyGrant` management.
* support compound key pseudonymisation
