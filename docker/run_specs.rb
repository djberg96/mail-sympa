# frozen_string_literal: true

require 'net/http'
require 'rbconfig'
require 'tempfile'

# Every container gets its own SQLite database and list state. No mail daemons
# are started; SOAP operations run synchronously and notification mail is spooled.
abort 'Sympa logging setup failed' unless system('rsyslogd', '-f', '/app/docker/test-syslog.conf', '-i', '/tmp/mail-sympa-syslog.pid')
abort 'Sympa database initialization failed' unless system('sympa', 'check')
abort 'Sympa fixture provisioning failed' unless system('perl', 'docker/seed_sympa.pl')
abort 'Sympa permissions setup failed' unless system('chown', '-R', 'sympa:sympa', '/var/lib/sympa', '/var/spool/sympa', '/etc/sympa')

server_log = Tempfile.new('mail-sympa-server')
server_pid = Process.spawn('/usr/sbin/apache2', '-f', '/app/docker/test-apache.conf', '-DFOREGROUND',
                           out: server_log, err: server_log)
status = 1

begin
  deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30
  health = URI('http://localhost:8080/sympa/wsdl')

  loop do
    if Process.waitpid(server_pid, Process::WNOHANG)
      server_pid = nil
      raise 'Sympa HTTP server exited before becoming ready.'
    end

    begin
      response = Net::HTTP.start(health.host, health.port, open_timeout: 1, read_timeout: 1) do |http|
        http.get(health.request_uri)
      end
      break if response.is_a?(Net::HTTPSuccess) && response.body.include?('definitions')
    rescue SystemCallError, Timeout::Error, EOFError
      # Wait for the server to open its socket.
    end

    raise 'Sympa HTTP server was not ready within 30 seconds.' if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

    sleep 0.1
  end

  puts 'Sympa HTTP server ready. Running specs...'
  system(RbConfig.ruby, '-S', 'rspec', '--format', 'documentation', *ARGV)
  status = $?.exitstatus || 1
rescue StandardError => error
  warn error.message
ensure
  if server_pid
    begin
      Process.kill('TERM', server_pid)
    rescue Errno::ESRCH
      # The server may have exited while the specs were running.
    end
    Process.waitpid(server_pid)
  end
  unless status.zero?
    server_log.rewind
    warn "Sympa HTTP server log:\n#{server_log.read}"
    warn "Sympa log:\n#{File.read('/var/log/mail-sympa.log')}" if File.file?('/var/log/mail-sympa.log')
  end
  server_log.close!
end

exit status
