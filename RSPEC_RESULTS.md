# RSpec verification

Verified on 19 November 2026 using `rake docker:build` and `rake docker:spec`:

```text
88 examples, 0 failures
```

The suite runs against Debian Bookworm's real Sympa 6.2.70 SOAP service under
Apache/FastCGI with SQLite, using Ruby 3.3. Every run provisions fresh users,
lists, subscriptions, and a trusted application in a disposable container.
No examples are excluded for mock-server limitations.

The tests cover authentication failures and sessions, list queries and topic
filters, SOAP arrays and structs, true and false permissions, trusted-app
credentials, subscriber changes, and list creation and closure. Mutation tests
verify the resulting server state. See [DOCKER_README.md](DOCKER_README.md) for
commands and fixture details.

This replaces the earlier mock-only results. SMTP delivery, other Sympa releases,
and production database deployments are outside this suite's scope.
