require 'rake'
require 'rake/clean'
require 'rake/testtask'

CLEAN.include("**/*.gem", "**/*.rbc")

namespace 'gem' do
  desc 'Remove any existing gem file'
  task :clean do
    Dir['*.gem'].each{ |f| File.delete(f) }
  end

  desc 'Build the mail-sympa gem'
  task :build => [:clean] do
    require 'rubygems/package'
    spec = Gem::Specification.load('mail-sympa.gemspec')
    Gem::Package.build(spec)
  end

  desc 'Install the mail-sympa gem'
  task :install => [:build] do
    file = Dir["*.gem"].first
    sh "gem install -l #{file}"
  end
end

Rake::TestTask.new('test') do |t|
  t.warning = true
  t.verbose = true
end

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new('spec') do |t|
    t.rspec_opts = ['--color', '--format', 'documentation']
  end

  desc 'Run RSpec tests against mock server'
  task :spec_mock => :spec

rescue LoadError
  # RSpec not available
  task :spec do
    puts "RSpec not available. Install it with: gem install rspec"
  end

  task :spec_mock => :spec
end

task :default => :test
