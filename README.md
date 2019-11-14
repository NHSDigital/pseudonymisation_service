# README

The `pseudonymisation_service` project is a Rails API-only application that allows demographics to be submitted, and pseudonymised versions to be returned.

## Basic Table Structure

Users can use pseudonymisation keys when a key grant has been given:

```
+------+      +----------+      +---------------------+
| User | ---> | KeyGrant | <--- | PseudonymisationKey |
+------+      +----------+      +---------------------+
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
