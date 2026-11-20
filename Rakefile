require 'rake'
require 'rake/clean'

CLEAN.include("**/*.gem", "**/*.rbc", "**/*.lock")

def container_runtime
  return ENV['CONTAINER_RUNTIME'] unless ENV['CONTAINER_RUNTIME'].to_s.empty?

  %w[docker podman].find do |runtime|
    ENV.fetch('PATH', '').split(File::PATH_SEPARATOR).any? do |directory|
      File.executable?(File.join(directory, runtime))
    end
  end || raise('Install Docker or Podman to run the containerized specs.')
end

namespace :docker do
  desc 'Build the image containing Ruby, real Sympa, Apache, and SQLite'
  task :build do
    sh container_runtime, 'build', '-f', File.join(__dir__, 'docker/Dockerfile'),
       '-t', ENV.fetch('MAIL_SYMPA_IMAGE', 'mail-sympa-test'), __dir__
  end

  desc 'Run RSpec against a freshly seeded real Sympa server in a disposable container'
  task :spec => :build do
    sh container_runtime, 'run', '--rm', '--network', 'none', ENV.fetch('MAIL_SYMPA_IMAGE', 'mail-sympa-test')
  end
end

namespace 'gem' do
  desc 'Remove any existing gem file'
  task :clean do
    Dir['*.gem'].each{ |f| File.delete(f) }
  end

  desc 'Build the mail-sympa gem'
  task :create => [:clean] do
    require 'rubygems/package'
    spec = Gem::Specification.load('mail-sympa.gemspec')
    spec.signing_key = File.join(Dir.home, '.ssh', 'gem-private_key.pem')
    Gem::Package.build(spec)
  end

  desc 'Install the mail-sympa gem'
  task :install => [:create] do
    file = Dir["*.gem"].first
    sh "gem install -l #{file}"
  end
end

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new('spec') do |t|
    t.rspec_opts = ['--color', '--format', 'documentation']
  end

rescue LoadError
  task :spec do
    abort 'RSpec not available. Run rake docker:spec or install dependencies with bundle install.'
  end

end

task :default => :spec
