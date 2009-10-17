require 'rake'
require 'rake/testtask'
include Config

desc "Install the mail-sympa library"
task :install_lib do
   dest = File.join(CONFIG['sitelibdir'], 'mail')
   Dir.mkdir(dest) unless File.exists? dest
   cp 'lib/mail/sympa.rb', dest, :verbose => true
end

desc 'Build the mail-sympa gem'
task :gem do
   spec = eval(IO.read('mail-sympa.gemspec'))
   Gem::Builder.new(spec).build
end

desc 'Install the mail-sympa library as a gem'
task :install_gem => [:gem] do
   file = Dir["*.gem"].first
   sh "gem install #{file}"
end

Rake::TestTask.new do |t|
   t.warning = true
   t.verbose = true
end
