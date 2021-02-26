require 'rubygems'

Gem::Specification.new do |spec|
  spec.name        = 'mail-sympa'
  spec.version     = '1.2.0'
  spec.authors     = ['Daniel J. Berger', 'David Salisbury', 'Mark Sallee']
  spec.license     = 'Artistic-2.0'
  spec.description = 'Ruby interface for the Sympa mailing list server'
  spec.email       = 'djberg96@gmail.com'
  spec.files       = Dir['**/*'].reject{ |f| f.include?('git') }
  spec.test_files  = ['test/test_mail_sympa.rb']
  spec.homepage    = 'http://github.com/djberg96/mail-sympa'

  spec.required_ruby_version = '>= 1.9.3'

  spec.add_dependency('soap4r-ruby1.9', '~> 2.0')
  spec.add_development_dependency('test-unit', '~> 3.3')
  spec.add_development_dependency('dbi-dbrc', '~> 1.4')

  spec.summary = <<-EOF
    The mail-sympa library provides a Ruby interface to the Sympa mailing
    list server software. This is a convenient and pretty wrapper for the
    various SOAP functions that Sympa server publishes.

    See http://www.sympa.org for more information.
  EOF
end
