require 'spec_helper'
require 'net/http'
require 'uri'

# Simple integration test bypassing SOAP4R issues
RSpec.describe "Mock Sympa SOAP Server Integration" do
  let(:endpoint) { 'http://localhost:8080/sympasoap' }

  describe "WSDL endpoint" do
    it "is accessible" do
      uri = URI(endpoint)
      response = Net::HTTP.get_response(uri)
      expect(response.code).to eq('200')
      expect(response.body).to include('definitions')
    end

    it "contains expected namespaces" do
      uri = URI(endpoint)
      response = Net::HTTP.get_response(uri)
      expect(response.body).to include('urn:sympasoap')
      expect(response.body).to include('login')
    end
  end

  describe "SOAP endpoint" do
    def make_soap_request(method, parameters = {})
      uri = URI(endpoint)

      # Build parameter XML
      param_xml = parameters.map { |k, v| "<#{k}>#{v}</#{k}>" }.join("\n      ")

      soap_request = <<~SOAP
        <?xml version="1.0" encoding="UTF-8"?>
        <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sym="urn:sympasoap">
          <soap:Body>
            <sym:#{method}>
              #{param_xml}
            </sym:#{method}>
          </soap:Body>
        </soap:Envelope>
      SOAP

      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.path)
      request['Content-Type'] = 'text/xml; charset=utf-8'
      request['SOAPAction'] = "urn:sympasoap##{method}"
      request.body = soap_request

      http.request(request)
    end

    it "accepts login requests" do
      response = make_soap_request('login', {
        email: 'postmaster@localhost',
        password: 'test'
      })

      expect(response.code).to eq('200')
      expect(response.body).to include('loginResponse')
      expect(response.body).to include('return')
    end

    it "accepts lists requests" do
      response = make_soap_request('lists', {})

      expect(response.code).to eq('200')
      expect(response.body).to include('listsResponse')
    end

    it "accepts add requests" do
      response = make_soap_request('add', {
        email: 'test@example.com',
        list: 'testlist',
        name: 'Test User'
      })

      expect(response.code).to eq('200')
      expect(response.body).to include('addResponse')
    end

    it "accepts del requests" do
      response = make_soap_request('del', {
        email: 'test@example.com',
        list: 'testlist'
      })

      expect(response.code).to eq('200')
      expect(response.body).to include('delResponse')
    end

    it "accepts info requests" do
      response = make_soap_request('info', {
        list: 'testlist'
      })

      expect(response.code).to eq('200')
      expect(response.body).to include('infoResponse')
    end

    it "accepts review requests" do
      response = make_soap_request('review', {
        list: 'testlist'
      })

      expect(response.code).to eq('200')
      expect(response.body).to include('reviewResponse')
    end
  end
end
