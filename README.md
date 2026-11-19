## Description
The mail-sympa library is Ruby interface for the Sympa mailing list management software.

## Prerequisites
* Savon 2.x
* Nokogiri 1.x

## Installation
`gem install mail-sympa`

## Testing in Docker

With Ruby, Rake, and Docker running on your host:

```sh
rake docker:build
rake docker:spec
```

The image contains Ruby, real Sympa, Apache, SQLite, and all test dependencies.
Each run seeds fresh users and lists, tests the real SOAP service, and removes
the container. See [DOCKER_README.md](DOCKER_README.md) for details and runtime overrides.

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

## Creating Lists

Supply a topic configured in the server's `topics.conf` when creating a list:

```ruby
mail.create_list('some_list', 'Example list', 'discussion_list', 'Description', 'computing')
```

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

