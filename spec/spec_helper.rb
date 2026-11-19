require 'rspec'

# Require mail/sympa with Savon support
require 'mail/sympa'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

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

  config.before(:suite) do
    require 'net/http'
    uri = URI(ENV.fetch('SYMPA_WSDL_URL', 'http://localhost:8080/sympa/wsdl'))
    response = Net::HTTP.start(uri.host, uri.port, open_timeout: 3, read_timeout: 5) do |http|
      http.get(uri.request_uri)
    end
    raise "Sympa WSDL unavailable at #{uri}: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess) && response.body.include?('definitions')

    puts "Testing real Sympa at #{ENV.fetch('SYMPA_ENDPOINT', 'http://localhost:8080/sympasoap')}"
  end
end
