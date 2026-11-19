# Real Sympa integration tests

Run from the repository root:

```sh
rake docker:build
rake docker:spec
```

The host needs Ruby, Rake, and a running Docker daemon. All application and test
dependencies are installed inside the image; no host `bundle install` is needed.

`docker:build` builds `mail-sympa-test` with Ruby 3.3 and Debian Bookworm's Sympa
6.2.70 package, Apache/FastCGI, and SQLite. `docker:spec` first builds the image
(reusing cached dependency layers), then runs a disposable container with:

1. A fresh SQLite database and Sympa list state.
2. Two password-authenticated users, two lists, a subscriber, and a trusted SOAP application.
3. The actual Sympa SOAP service and WWSympa WSDL endpoint served by Apache.
4. The complete RSpec suite, with no excluded examples.

The specs verify valid and invalid authentication, sessions, list discovery,
structured SOAP results, permissions, trusted-app calls, subscriber changes,
and list creation and closure. Assertions check resulting server state as well
as return values.

The runner prints the installed Sympa package version, waits up to 30 seconds
for HTTP readiness, returns a failing status
on provisioning, startup, or spec failures, and prints the HTTP server log when
startup or tests fail, along with Sympa's syslog. Docker removes the container afterward, including its
database, lists, and queued notifications.

The source is copied at build time, so each `docker:spec` run includes current
edits without writing gems or lockfiles into the checkout. No host ports,
persistent volumes, external database, web setup, or `~/.dbirc` are needed.
The test container runs with networking disabled; localhost remains available.
Mail delivery daemons are not started.

## Runtime and image overrides

Docker is preferred; Podman is used if Docker is not installed. To select one
explicitly:

```sh
CONTAINER_RUNTIME=podman rake docker:spec
```

The selected runtime must already be running. Set `MAIL_SYMPA_IMAGE` to change
the tag used for both building and running:

```sh
MAIL_SYMPA_IMAGE=mail-sympa-dev rake docker:build docker:spec
```

After building, run selected examples or pass RSpec options:

```sh
docker run --rm --network none mail-sympa-test spec/mail_sympa_spec.rb --seed 1234
```

## Fixtures and configuration

The test domain is `sympa.test`; Apache listens on container-local port 8080.
The listmaster is `postmaster@sympa.test` and the second user is
`reader@example.test`, both with password `test`. The `testlist` list contains
the reader; `partners` starts empty. Both lists use topic `testlist/testlist`.
The trusted application is `mail-sympa-tests`, with password `test-app-password`
and permission to proxy `USER_EMAIL`. These credentials belong only to the
throwaway test environment.

The relevant setup is in `docker/test-sympa.conf`, `docker/test-apache.conf`,
`docker/test-topics.conf`, and `docker/seed_sympa.pl`. SQLite is a supported Sympa
backend, and keeps this SOAP integration environment self-contained. This suite
does not test SMTP delivery or a production deployment's database configuration.

To run specs on the host against an equivalently provisioned real server, use
`bundle install` followed by `bundle exec rake spec`. Optional variables are
`SYMPA_ENDPOINT`, `SYMPA_WSDL_URL`, `SYMPA_TEST_USER`, and `SYMPA_TEST_PASSWORD`.
The server must contain the fixture lists, topic, reader, and trusted application
above: these tests change server state.

Server behavior follows the [Sympa SOAP/HTTP API](https://www.sympa.community/manual/customize/soap-api.html).
See also Sympa's [SQLite setup instructions](https://www.sympa.community/manual/install/setup-database-sqlite.html).

The older Compose files and setup scripts are legacy experiments;
neither rake task uses them.

The retired SOAP simulator and its support files are preserved on the
`archive/mock-sympa` branch.
