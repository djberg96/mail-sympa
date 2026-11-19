# Savon integration

The client uses Savon 2.x and Nokogiri. Its SOAP behavior is now verified against
real Sympa 6.2.70 through the containerized suite described in
[DOCKER_README.md](DOCKER_README.md).

Real-server testing identified and corrected several issues in the previous
mock-oriented implementation:

- Authenticated operations now use `authenticateAndRun` with a session cookie.
- Requests use Sympa's required `namespace#method` SOAPAction and encoded parameter arrays.
- Trusted-application calls use `authenticateRemoteAppAndRun` with the same array encoding.
- Responses decode native SOAP values, including empty and singleton arrays,
  structs, and false booleans. Mock-specific JSON parsing has been removed.
- Login validates the returned cookie, canonicalizes the email, and clears an
  existing session when reauthentication fails.
- Server fault details and transport failures surface as `Mail::Sympa::Error`.

The public method names and aliases remain available. List creation requires a
valid server-configured topic; see the README example.

Verification: **88 examples, 0 failures**, with no mock exclusions. These results
replace the earlier migration report, whose mock-based assertions did not
establish real-server compatibility. They cover the tested server version and
SOAP operations, without asserting compatibility with every deployment or Ruby
version.
