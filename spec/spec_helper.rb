require 'rspec'

# Require mail/sympa with Savon support
require 'mail/sympa'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Filter out tests that don't work with mock server
  config.filter_run_excluding :skip_mock

  # Custom matcher for boolean values
  RSpec::Matchers.define :be_boolean do
    match do |actual|
      [true, false].include?(actual)
    end

    description do
      "be true or false"
    end

    failure_message do |actual|
      "expected #{actual.inspect} to be true or false"
    end
  end

  # Print helpful information before running tests
  config.before(:suite) do
    puts "\n" + "="*60
    puts "Running Mail::Sympa RSpec test suite"
    puts "Mock Sympa server should be running on http://localhost:8080/sympasoap"
    puts "="*60 + "\n"
  end

  # Check if mock server is running before tests
  config.before(:suite) do
    require 'net/http'
    require 'uri'

    begin
      uri = URI('http://localhost:8080/sympasoap')
      response = Net::HTTP.get_response(uri)
      if response.code == '200'
        puts "✓ Mock Sympa server is running and accessible"
      else
        puts "⚠ Mock Sympa server responded with code #{response.code}"
      end
    rescue => e
      puts "✗ Could not connect to mock Sympa server: #{e.message}"
      puts "Please ensure the mock server is running:"
      puts "  cd docker && ./setup-test-env.sh mock"
      exit 1
    end
  end

  config.after(:suite) do
    puts "\n" + "="*60
    puts "Test suite completed"
    puts "="*60
  end
end
