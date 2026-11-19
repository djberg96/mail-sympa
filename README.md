## Description

The mail-sympa library is a Ruby interface for the Sympa mailing list management software.

## Prerequisites

* Savon 2.x
* Nokogiri 1.x

## Installation

```sh
gem install mail-sympa
```

## Synopsis

```ruby
require 'mail/sympa' # or require 'mail-sympa'

mail = Mail::Sympa.new(server, namespace)
mail.login(email, password)

# Enumerate over each list and inspect it
mail.lists.each do |list|
  p list
end

# Add a user quietly
mail.add('foo@bar.com', 'some_list', 'Mr. Foo', true)
```

## Creating Lists

Supply a topic configured in the server's `topics.conf` when creating a list:

```ruby
mail.create_list('some_list', 'Example list', 'discussion_list', 'Description', 'computing')
```

## SOAP Integration

The client uses Savon 2.x and Nokogiri. Its SOAP behavior is verified against
real Sympa 6.2.70 through the containerized suite below. The public method names
and aliases remain available.

* Authenticated operations use `authenticateAndRun` with a session cookie.
* Requests use Sympa's required `namespace#method` SOAPAction and encoded
  parameter arrays.
* Trusted-application calls use `authenticateRemoteAppAndRun` with the same
  array encoding.
* Responses decode native SOAP values, including empty and singleton arrays,
  structs, and false booleans.
* Login validates the returned cookie, canonicalizes the email, and clears an
  existing session when reauthentication fails.
* Server fault details and transport failures surface as `Mail::Sympa::Error`.

See the [Sympa SOAP/HTTP API](https://www.sympa.community/manual/customize/soap-api.html)
for the server's service contract.

## Testing in Docker

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

The runner prints the installed Sympa package version, waits up to 30 seconds
for HTTP readiness, and returns a failing status on provisioning, startup, or
spec failures. Startup and test failures print the HTTP server log and Sympa's
syslog. Docker removes the container afterward, including its database, lists,
and queued notifications.

The source is copied at build time, so each `docker:spec` run includes current
edits without writing gems or lockfiles into the checkout. No host ports,
persistent volumes, external database, web setup, or `~/.dbirc` are needed.
The test container runs with networking disabled; localhost remains available.
Mail delivery daemons are not started.

### Runtime and Image Overrides

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

### Fixtures and Configuration

The test domain is `sympa.test`; Apache listens on container-local port 8080.
The listmaster is `postmaster@sympa.test` and the second user is
`reader@example.test`, both with password `test`. The `testlist` list contains
the reader; `partners` starts empty. Both lists use topic `testlist/testlist`.
The trusted application is `mail-sympa-tests`, with password `test-app-password`
and permission to proxy `USER_EMAIL`. These credentials belong only to the
throwaway test environment.

The relevant setup is in [docker/test-sympa.conf](docker/test-sympa.conf),
[docker/test-apache.conf](docker/test-apache.conf),
[docker/test-topics.conf](docker/test-topics.conf), and
[docker/seed_sympa.pl](docker/seed_sympa.pl). SQLite keeps this SOAP integration
environment self-contained; see Sympa's
[SQLite setup instructions](https://www.sympa.community/manual/install/setup-database-sqlite.html).

### Test Coverage and Results

Verified on 19 November 2026 using `rake docker:build` and `rake docker:spec`:

```text
88 examples, 0 failures
```

No examples are excluded. Tests cover valid and invalid authentication,
sessions, list discovery and topic filters, SOAP arrays and structs, true and
false permissions, trusted-app credentials, subscriber changes, and list
creation and closure. Mutation tests verify the resulting server state as
well as return values.

These results cover the tested server version and SOAP operations. SMTP
delivery, other Sympa releases, other Ruby versions, and production database
deployments are outside this suite's scope.

### Running Specs on the Host

To run specs against an equivalently provisioned real server, use
`bundle install` followed by `bundle exec rake spec`. Optional variables are
`SYMPA_ENDPOINT`, `SYMPA_WSDL_URL`, `SYMPA_TEST_USER`, and `SYMPA_TEST_PASSWORD`.
The server must contain the fixture lists, topic, reader, and trusted application
above: these tests change server state.

The retired SOAP simulator and its support files are preserved on the
`archive/mock-sympa` branch.

## Acknowledgements

Thanks go to Blair Christensen for some nice patches for this library.

## License

Artistic-2.0

## Copyright

(C) 2010-2011 Daniel J. Berger, Mark Sallee, David Salisbury, Blair Christensen
All Rights Reserved

## Warranty

This library is provided "as is" and without any express or
implied warranties, including, without limitation, the implied
warranties of merchantability and fitness for a particular purpose.

## Notes

See http://www.sympa.org for details.

## Authors

* Daniel Berger
* David Salisbury
* Mark Sallee
* Blair Christensen
