require 'rubygems'

Gem::Specification.new do |spec|
  spec.name        = 'mail-sympa'
  spec.version     = '1.2.0'
  spec.authors     = ['Daniel J. Berger', 'David Salisbury', 'Mark Sallee']
  spec.license     = 'Artistic-2.0'
  spec.description = 'Ruby interface for the Sympa mailing list server'
  spec.email       = 'djberg96@gmail.com'
  spec.files       = Dir['**/*'].reject{ |f| f.include?('git') }
  spec.test_files  = ['test/test_mail_sympa.rb', 'spec/mail_sympa_spec.rb']
  spec.homepage    = 'http://github.com/djberg96/mail-sympa'

  # Using Savon for SOAP client functionality (modern, Ruby 3.3+ compatible)
  spec.add_dependency('savon', '~> 2.12')

  # Additional dependency for XML handling
  spec.add_dependency('nokogiri', '~> 1.13')

  spec.add_development_dependency('rake')
  spec.add_development_dependency('rspec', '~> 3.0')

  spec.metadata = {
    'homepage_uri'      => 'https://github.com/djberg96/mail-sympa',
    'bug_tracker_uri'   => 'https://github.com/djberg96/mail-sympa/issues',
    'changelog_uri'     => 'https://github.com/djberg96/mail-sympa/blob/main/CHANGES.md',
    'documentation_uri' => 'https://github.com/djberg96/mail-sympa/wiki',
    'source_code_uri'   => 'https://github.com/djberg96/mail-sympa',
    'wiki_uri'          => 'https://github.com/djberg96/mail-sympa/wiki'
  }

  spec.summary = <<-EOF
    The mail-sympa library provides a Ruby interface to the Sympa mailing
    list server software. This is a convenient and pretty wrapper for the
    various SOAP functions that Sympa server publishes.

    See http://www.sympa.org for more information.
  EOF
end
