require 'spec_helper'
require 'net/http'
require 'nokogiri'

RSpec.describe 'Real Sympa SOAP integration' do
  let(:endpoint) { ENV.fetch('SYMPA_ENDPOINT', 'http://localhost:8080/sympasoap') }

  it 'publishes the real service contract through WWSympa' do
    wsdl = Net::HTTP.get(URI(ENV.fetch('SYMPA_WSDL_URL', 'http://localhost:8080/sympa/wsdl')))
    document = Nokogiri::XML(wsdl) { |config| config.strict.nonet }
    operations = document.xpath('//*[local-name()="portType"]/*[local-name()="operation"]/@name').map(&:value)
    expect(operations).to include('login', 'authenticateAndRun', 'authenticateRemoteAppAndRun', 'createList')
  end

  it 'rejects SOAP calls without authentication' do
    client = Savon.client(endpoint: endpoint, namespace: 'urn:sympasoap')
    expect {
      client.call(:review, soap_action: 'urn:sympasoap#review', message: { list: 'testlist' })
    }.to raise_error(Savon::SOAPFault, /User not authenticated/)
  end

  it 'rejects fabricated session cookies' do
    sympa = Mail::Sympa.new(endpoint)
    sympa.login(ENV.fetch('SYMPA_TEST_USER', 'postmaster@sympa.test'), ENV.fetch('SYMPA_TEST_PASSWORD', 'test'))
    sympa.instance_variable_set(:@cookie, 'not-a-real-session')
    expect { sympa.review('testlist') }.to raise_error(Mail::Sympa::Error, /Could not get email from cookie/)
  end
end
