## Description
The mail-sympa library is Ruby interface for the Sympa mailing list management software.

## Prerequisites
* soap4r 1.5.8 or later
* xmlparser

## Installation
`gem install mail-sympa`

## Synopsis
```ruby
require 'mail/sympa' # or require 'mail-sympa'

mail = Mail::Sympa.new(server, namespace)
mail.login(email, password)

# Enumerate over each list and inspect it
puts mail.lists.each do |list|
  p list
end

# Add a user quietly
mail.add('foo@bar.com', 'some_list', 'Mr. Foo', true)
```

## Known Issues
The `Sympa#add` and `Sympa#del` methods return an empty string instead of
a boolean. I am unsure why.

## Acknowledgements
Thanks go to Blair Christensen for some nice patches for this library.

## TODO
The test suite should be reworked to use rspec and a mock sympa server instead
of relying on an actual server to test against.

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

