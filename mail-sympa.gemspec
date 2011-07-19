require 'rubygems'

Gem::Specification.new do |gem|
  gem.name        = 'mail-sympa'
  gem.version     = '1.1.0'
  gem.authors     = ['Daniel J. Berger', 'David Salisbury', 'Mark Sallee']
  gem.license     = 'Artistic 2.0'
  gem.description = 'Ruby interface for the Sympa mailing list server'
  gem.email       = 'djberg96@gmail.com'
  gem.files       = Dir['**/*'].reject{ |f| f.include?('git') }
  gem.test_files  = ['test/test_mail_sympa.rb']
  gem.homepage    = 'http://github.com/djberg96/mail-sympa'

  gem.extra_rdoc_files  = ['README', 'CHANGES', 'MANIFEST']

  gem.add_dependency('soap4r', '>= 1.5.8')

  gem.summary = <<-EOF
    The mail-sympa library provides a Ruby interface to the Sympa mailing
    list server software. This is a convenient and pretty wrapper for the
    various SOAP functions that Sympa server publishes.

    See http://www.sympa.org for more information.
  EOF
end
