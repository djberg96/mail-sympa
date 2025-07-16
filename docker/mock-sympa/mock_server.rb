#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple Mock Sympa SOAP Server for testing mail-sympa Ruby library
# This provides basic SOAP endpoints that the Ruby library expects

require 'sinatra'
require 'logger'
require 'json'

# Configure logging
set :logging, true
set :port, 8080
set :bind, '0.0.0.0'

# Create logger
logger = Logger.new(STDOUT)
logger.level = Logger::INFO

# Helper method to extract SOAP method name from request body
def extract_soap_method(soap_body, logger)
  # Look for method calls in the SOAP body, prioritizing namespaced elements
  method_patterns = [
    /<sym:(\w+)[^>]*>/, # sym: namespace (most specific)
    /<sympa:(\w+)[^>]*>/, # sympa: namespace
    /<(\w+)[^>]*>.*?<\/\1>/, # General method pattern with closing tag
    /<(\w+)[^>]*>/ # General method pattern
  ]

  method_patterns.each do |pattern|
    matches = soap_body.scan(pattern).flatten
    matches.each do |method|
      unless %w[Envelope Body Header soap xmlns].include?(method)
        logger.info("Found method: #{method} using pattern: #{pattern}")
        return method
      end
    end
  end

  # If no method found, try to extract from SOAPAction header or fallback
  logger.warn("Could not extract method from SOAP body: #{soap_body[0..100]}...")
  'unknown'
end

# Helper method to create SOAP response
def create_soap_response(method, result)
  result_xml = case result
               when Array
                 result.inspect # Convert array to string representation like Python
               when String
                 result
               else
                 result.to_s
               end

  <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sym="urn:sympasoap">
      <soap:Body>
        <sym:#{method}Response>
          <return>#{result_xml}</return>
        </sym:#{method}Response>
      </soap:Body>
    </soap:Envelope>
  XML
end

# Helper method to create SOAP fault
def create_soap_fault(fault_string)
  <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
      <soap:Body>
        <soap:Fault>
          <faultcode>Client</faultcode>
          <faultstring>#{fault_string}</faultstring>
        </soap:Fault>
      </soap:Body>
    </soap:Envelope>
  XML
end

# GET endpoint for WSDL
get '/sympasoap' do
  content_type 'text/xml'

  <<~WSDL
    <?xml version="1.0" encoding="UTF-8"?>
    <definitions xmlns="http://schemas.xmlsoap.org/wsdl/"
                 xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
                 xmlns:tns="urn:sympasoap"
                 targetNamespace="urn:sympasoap"
                 xmlns:xsd="http://www.w3.org/2001/XMLSchema">

      <types>
        <xsd:schema targetNamespace="urn:sympasoap">
          <xsd:element name="login" type="xsd:string"/>
          <xsd:element name="loginResponse" type="xsd:string"/>
        </xsd:schema>
      </types>

      <message name="loginRequest">
        <part name="email" type="xsd:string"/>
        <part name="password" type="xsd:string"/>
      </message>

      <message name="loginResponse">
        <part name="return" type="xsd:string"/>
      </message>

      <portType name="SympaPortType">
        <operation name="login">
          <input message="tns:loginRequest"/>
          <output message="tns:loginResponse"/>
        </operation>
      </portType>

      <binding name="SympaBinding" type="tns:SympaPortType">
        <soap:binding style="rpc" transport="http://schemas.xmlsoap.org/soap/http"/>
        <operation name="login">
          <soap:operation soapAction="urn:sympasoap#login"/>
          <input><soap:body use="literal" namespace="urn:sympasoap"/></input>
          <output><soap:body use="literal" namespace="urn:sympasoap"/></output>
        </operation>
      </binding>

      <service name="SympaService">
        <port name="SympaPort" binding="tns:SympaBinding">
          <soap:address location="http://localhost:8080/sympasoap"/>
        </port>
      </service>

    </definitions>
  WSDL
end

# POST endpoint for SOAP requests
post '/sympasoap' do
  content_type 'text/xml'

  begin
    soap_body = request.body.read
    logger.info("SOAP request received: #{soap_body[0..500]}...")

    method = extract_soap_method(soap_body, logger)
    logger.info("Extracted method: #{method}")

    # Handle different SOAP methods
    response = case method
               when 'login'
                 # Extract email from request
                 email_match = soap_body.match(/<email[^>]*>([^<]+)<\/email>/)
                 email = email_match ? email_match[1] : 'unknown@example.com'
                 logger.info("Login request for: #{email}")

                 # Return a mock session cookie
                 create_soap_response('login', 'mock_session_12345')

               when 'lists'
                 logger.info('Lists request')

                 # Check for bogus topic that should return empty
                 if soap_body.include?('bogus_topic_that_does_not_exist')
                   create_soap_response('lists', [])
                 else
                   create_soap_response('lists', %w[testlist partners])
                 end

               when 'complexLists'
                 logger.info('Complex lists request')

                 # Check for bogus topic that should return empty
                 if soap_body.include?('bogus_topic_that_does_not_exist')
                   create_soap_response('complexLists', '[]')
                 else
                   # Return mock complex list data as string representation
                   create_soap_response('complexLists', '[{"name":"testlist","subject":"Test List"},{"name":"partners","subject":"Partners List"}]')
                 end               when 'info'
                 # Parse parameters for list name (first parameter) - match sym:parameters specifically
                 parameters_match = soap_body.match(/<sym:parameters>([^<]+)<\/sym:parameters>/)
                 list_name = parameters_match ? parameters_match[1] : 'unknown'
                 logger.info("Info request for list: #{list_name}")

                 # Return JSON string format that can be parsed to Hash
                 info_json = {
                   'listname' => list_name,
                   'subject' => "Subject for #{list_name}",
                   'homepage' => "http://example.com/#{list_name}"
                 }.to_json
                 create_soap_response('info', info_json)

               when 'add'
                 email_match = soap_body.match(/<email[^>]*>([^<]+)<\/email>/)
                 list_match = soap_body.match(/<list[^>]*>([^<]+)<\/list>/)
                 email = email_match ? email_match[1] : 'unknown'
                 list_name = list_match ? list_match[1] : 'unknown'
                 logger.info("Add request: #{email} to #{list_name}")
                 create_soap_response('add', 'true')

               when 'del'
                 email_match = soap_body.match(/<email[^>]*>([^<]+)<\/email>/)
                 list_match = soap_body.match(/<list[^>]*>([^<]+)<\/list>/)
                 email = email_match ? email_match[1] : 'unknown'
                 list_name = list_match ? list_match[1] : 'unknown'
                 logger.info("Delete request: #{email} from #{list_name}")
                 create_soap_response('del', 'true')

               when 'review'
                 # Parse parameters for list name (first parameter) - match sym:parameters specifically
                 logger.info("DEBUG: Starting review processing")
                 parameters_match = soap_body.match(/<sym:parameters>([^<]+)<\/sym:parameters>/)
                 logger.info("DEBUG: parameters_match result: #{parameters_match.inspect}")
                 list_name = parameters_match ? parameters_match[1] : 'unknown'
                 logger.info("Review request for list: #{list_name}")

                 # Return different responses based on list name
                 if list_name == 'partners'
                   create_soap_response('review', ['no_subscribers'])
                 else
                   create_soap_response('review', %w[test@example.com user@example.com])
                 end

               when 'which'
                 email_match = soap_body.match(/<email[^>]*>([^<]+)<\/email>/)
                 email = email_match ? email_match[1] : 'unknown'
                 logger.info("Which request for: #{email}")
                 create_soap_response('which', ['testlist'])

               when 'amI'
                 logger.info('AmI request')
                 create_soap_response('amI', 'true')

               when 'subscribe'
                 list_match = soap_body.match(/<list[^>]*>([^<]+)<\/list>/)
                 list_name = list_match ? list_match[1] : 'unknown'
                 logger.info("Subscribe request for list: #{list_name}")
                 create_soap_response('subscribe', 'true')

               when 'signoff'
                 list_match = soap_body.match(/<list[^>]*>([^<]+)<\/list>/)
                 list_name = list_match ? list_match[1] : 'unknown'
                 logger.info("Signoff request for list: #{list_name}")
                 create_soap_response('signoff', 'true')

               when 'createList'
                 list_match = soap_body.match(/<list[^>]*>([^<]+)<\/list>/)
                 list_name = list_match ? list_match[1] : 'unknown'
                 logger.info("Create list request for: #{list_name}")
                 create_soap_response('createList', 'true')

               when 'closeList'
                 list_match = soap_body.match(/<list[^>]*>([^<]+)<\/list>/)
                 list_name = list_match ? list_match[1] : 'unknown'
                 logger.info("Close list request for: #{list_name}")
                 create_soap_response('closeList', 'true')

               else
                 logger.warn("Unknown method: #{method}")
                 create_soap_fault("Unknown method: #{method}")
               end

    logger.info("Sending response: #{response[0..300]}...")
    response

  rescue => e
    logger.error("Error processing SOAP request: #{e}")
    logger.error(e.backtrace.join("\n"))
    create_soap_fault("Server error: #{e}")
  end
end

# Health check endpoint
get '/health' do
  content_type 'application/json'
  { status: 'ok', service: 'Ruby Mock Sympa SOAP Server' }.to_json
end

# Start message
logger.info('Starting Ruby Mock Sympa SOAP Server on port 8080')
