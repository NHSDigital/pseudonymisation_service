# README

## Authentication

Users are authenticated with tokens supplied in the request headers.
A token can be generated for a user using the following rake task:

```
$ rails users:generate_token
```
