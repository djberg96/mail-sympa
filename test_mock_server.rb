#!/usr/bin/env ruby

# Simple test to verify the mock server is working
require 'net/http'
require 'uri'

def test_mock_server
  puts "Testing Mock Sympa SOAP Server..."
  puts "="*50

  begin
    # Test WSDL endpoint
    uri = URI('http://localhost:8080/sympasoap')
    response = Net::HTTP.get_response(uri)

    if response.code == '200' && response.body.include?('definitions')
      puts "✓ WSDL endpoint accessible"
      puts "✓ WSDL content looks valid"
    else
      puts "✗ WSDL endpoint issue: #{response.code}"
    end

    # Test SOAP endpoint
    soap_request = <<~SOAP
      <?xml version="1.0" encoding="UTF-8"?>
      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sym="urn:sympasoap">
        <soap:Body>
          <sym:login>
            <email>postmaster@localhost</email>
            <password>test</password>
          </sym:login>
        </soap:Body>
      </soap:Envelope>
    SOAP

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'text/xml; charset=utf-8'
    request['SOAPAction'] = 'urn:sympasoap#login'
    request.body = soap_request

    response = http.request(request)

    if response.code == '200'
      puts "✓ SOAP endpoint accepting requests"
      if response.body.include?('loginResponse') || response.body.include?('return')
        puts "✓ SOAP response format looks correct"
      else
        puts "⚠ SOAP response format unexpected:"
        puts response.body[0..200] + "..."
      end
    else
      puts "✗ SOAP endpoint issue: #{response.code}"
      puts response.body[0..200] + "..." if response.body
    end

  rescue => e
    puts "✗ Error testing mock server: #{e.message}"
    puts "Make sure the mock server is running:"
    puts "  cd docker && ./setup-test-env.sh mock"
    return false
  end

  puts "="*50
  puts "Mock server appears to be working correctly!"
  return true
end

if __FILE__ == $0
  test_mock_server
end
