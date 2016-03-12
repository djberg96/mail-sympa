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
    spec = eval(IO.read('mail-sympa.gemspec'))
    Gem::Package.build(spec, true)
  end

  desc 'Install the mail-sympa gem'
  task :install => [:build] do
    file = Dir["*.gem"].first
    sh "gem install #{file}"
  end
end

Rake::TestTask.new('test') do |t|
  t.warning = true
  t.verbose = true
end

task :default => :test
