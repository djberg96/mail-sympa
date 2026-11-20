## 1.3.1 - 20-Nov-2026
* Fix the version, oops.

## 1.3.0 - 19-Nov-2026
* Replaced soap4r-ruby1.9 with Savon 2.x and Nokogiri for SOAP communication.
* Structured SOAP values now return as hashes with symbol keys, such as
  `:subject` and `:list_address`, instead of `SOAP::Mapping` objects.
* Login now normalizes email addresses, validates session cookies, and clears
  an existing session when reauthentication fails.
* SOAP faults and transport failures now raise `Mail::Sympa::Error`, including
  server fault details when available.
* Fixed the `am_i?` error message to include the invalid function name.
* Replaced the test-unit suite with RSpec and made `rake spec` the default task.
  Removed the dbi-dbrc dependency and `.dbirc` test configuration.
* Added `rake docker:build` and `rake docker:spec` for self-contained integration
  tests against real Sympa, including authentication and changes to server state.
* Updated gem build/install tasks, added RubyGems metadata, and standardized the
  license identifier as `Artistic-2.0`.
* Converted documentation to Markdown, consolidated usage and testing details
  in README.md, and updated the manifest.

## 1.2.0 - 12-Mar-2016
* No longer supports Ruby 1.8, and made corresponding changes to code.
* Updated the Rakefile tasks. Now assumes Rubygems 2.x.
* Added a mail-sympa.rb file for convenience.
* Removed Gemfile.lock.

## 1.1.0 - 19-Jul-2011
* Added the `authenticate_remote_app_and_run` method to run in trusted context
  and support for Ruby 1.9+. Thanks go to Blair Christensen for patches.

## 1.0.0 - 16-Jun-2011
* Added the `create_list` and `close_list` methods and corresponding tests. Thanks
  go to Blair Christensen for both.
* Added 0.1.1 changes to this file that I forgot.
* Bumped the version to 1.0.0, as I have no more future plans for this library.

## 0.1.1 - 17-Jan-2011
* Fixed two parser warnings caused by missing commas.
* Added a clean and default task to the Rakefile.

## 0.1.0 - 13-Apr-2010
* Initial release
