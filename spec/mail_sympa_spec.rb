require 'spec_helper'
require 'mail/sympa'

RSpec.describe Mail::Sympa do
  let(:endpoint) { 'http://localhost:8080/sympasoap' }
  let(:sympa) { Mail::Sympa.new(endpoint) }
  let(:test_user) { 'postmaster@localhost' }
  let(:test_password) { 'test' }
  let(:test_list) { 'testlist' }
  let(:empty_list) { 'partners' }

  # Helper method to ensure the sympa instance is logged in
  def login_sympa
    sympa.login(test_user, test_password)
  end

  # Helper method to create a list if it doesn't exist
  def ensure_list_exists(list_name)
    login_sympa
    begin
      sympa.info(list_name)
    rescue => e
      # List doesn't exist, try to create it
      begin
        sympa.create_list(list_name, "Test list #{list_name}")
      rescue => create_error
        fail "List #{list_name} does not exist and could not be created: #{create_error}"
      end
    end
  end

  describe 'class constants and attributes' do
    it 'has the expected version constant' do
      expect(Mail::Sympa::VERSION).to eq('1.2.0')
    end
  end

  describe '#initialize' do
    it 'creates a new instance with an endpoint' do
      expect(sympa).to be_a(Mail::Sympa)
      expect(sympa.endpoint).to eq(endpoint)
    end

    it 'sets the default namespace' do
      expect(sympa.namespace).to eq('urn:sympasoap')
    end

    it 'allows custom namespace' do
      custom_sympa = Mail::Sympa.new(endpoint, 'custom:namespace')
      expect(custom_sympa.namespace).to eq('custom:namespace')
    end
  end

  describe '#endpoint' do
    it 'responds to endpoint method' do
      expect(sympa).to respond_to(:endpoint)
    end

    it 'returns the endpoint as a string' do
      expect(sympa.endpoint).to be_a(String)
      expect(sympa.endpoint).to eq(endpoint)
    end

    it 'is a readonly attribute' do
      expect { sympa.endpoint = 'foo' }.to raise_error(NoMethodError)
    end
  end

  describe '#namespace' do
    it 'responds to namespace method' do
      expect(sympa).to respond_to(:namespace)
    end

    it 'returns the namespace as a string' do
      expect(sympa.namespace).to be_a(String)
      expect(sympa.namespace).to eq('urn:sympasoap')
    end

    it 'is a readonly attribute' do
      expect { sympa.namespace = 'foo' }.to raise_error(NoMethodError)
    end
  end

  describe '#login' do
    it 'responds to login method' do
      expect(sympa).to respond_to(:login)
    end

    it 'works with valid credentials' do
      expect { login_sympa }.not_to raise_error
      expect(sympa.cookie).not_to be_nil
      expect(sympa.cookie).to be_a(String)
    end

    it 'raises an error with invalid credentials', :skip_mock do
      # Skip this test when using mock server as it accepts any credentials
      expect { sympa.login('bogus', 'bogus') }.to raise_error(Mail::Sympa::Error)
    end

    it 'requires exactly two arguments' do
      expect { sympa.login }.to raise_error(ArgumentError)
      expect { sympa.login('bogus') }.to raise_error(ArgumentError)
    end

    it 'returns a session cookie string' do
      result = login_sympa
      expect(result).to be_a(String)
    end
  end

  describe '#lists' do
    before { login_sympa }

    it 'responds to lists method' do
      expect(sympa).to respond_to(:lists)
    end

    it 'returns an array of lists' do
      lists = sympa.lists
      expect(lists).to be_a(Array)
      expect(lists.first).to be_a(String) if lists.any?
    end

    it 'accepts a topic argument' do
      ensure_list_exists(test_list)
      result = sympa.lists(test_list)
      expect(result).to be_a(Array)
    end

    it 'accepts topic and subtopic arguments' do
      ensure_list_exists(test_list)
      result = sympa.lists(test_list, test_list)
      expect(result).to be_a(Array)
    end

    it 'returns empty array for non-existent topic' do
      result = sympa.lists('bogus_topic_that_does_not_exist')
      expect(result).to eq([])
    end

    it 'accepts maximum of two arguments' do
      expect { sympa.lists('a', 'b', 'c') }.to raise_error(ArgumentError)
    end
  end

  describe '#complex_lists' do
    before { login_sympa }

    it 'responds to complex_lists method' do
      expect(sympa).to respond_to(:complex_lists)
    end

    it 'has complexLists alias' do
      expect(sympa).to respond_to(:complexLists)
    end

    it 'returns an array of complex objects' do
      lists = sympa.complex_lists
      expect(lists).to be_a(Array)
      expect(lists.first).to be_a(Hash) if lists.any?
    end

    it 'accepts topic and subtopic arguments' do
      result = sympa.complex_lists(test_list)
      expect(result).to be_a(Array)

      result = sympa.complex_lists(test_list, test_list)
      expect(result).to be_a(Array)
    end

    it 'returns empty array for non-existent topic' do
      result = sympa.complex_lists('bogus_topic_that_does_not_exist')
      expect(result).to eq([])
    end

    it 'accepts maximum of two arguments' do
      expect { sympa.complex_lists('a', 'b', 'c') }.to raise_error(ArgumentError)
    end
  end

  describe '#info' do
    before { login_sympa }

    it 'responds to info method' do
      expect(sympa).to respond_to(:info)
    end

    it 'returns information about a list' do
      ensure_list_exists(test_list)
      info = sympa.info(test_list)
      expect(info).to be_a(Hash)
    end

    it 'requires login' do
      new_sympa = Mail::Sympa.new(endpoint)
      expect { new_sympa.info(test_list) }.to raise_error(Mail::Sympa::Error, 'must login first')
    end
  end

  describe '#review' do
    before { login_sympa }

    it 'responds to review method' do
      expect(sympa).to respond_to(:review)
    end

    it 'returns an array of subscribers' do
      ensure_list_exists(test_list)
      subscribers = sympa.review(test_list)
      expect(subscribers).to be_a(Array)
      expect(subscribers.first).to be_a(String) if subscribers.any?
    end

    it 'returns no_subscribers for empty list' do
      ensure_list_exists(empty_list)
      subscribers = sympa.review(empty_list)
      expect(subscribers).to eq(['no_subscribers'])
    end

    it 'raises error for non-existent list', :skip_mock do
      # Skip this test when using mock server
      expect { sympa.review('bogus_list_xyz_123') }.to raise_error(Mail::Sympa::Error)
    end

    it 'requires login' do
      new_sympa = Mail::Sympa.new(endpoint)
      expect { new_sympa.review(test_list) }.to raise_error(Mail::Sympa::Error, 'must login first')
    end
  end

  describe '#which' do
    it 'responds to which method' do
      expect(sympa).to respond_to(:which)
    end

    it 'requires login' do
      expect { sympa.which('user', 'app', 'pass') }.to raise_error(Mail::Sympa::Error, 'must login first')
    end
  end

  describe '#complex_which' do
    it 'responds to complex_which method' do
      expect(sympa).to respond_to(:complex_which)
    end

    it 'has complexWhich alias' do
      expect(sympa).to respond_to(:complexWhich)
    end

    it 'requires login' do
      expect { sympa.complex_which('user', 'app', 'pass') }.to raise_error(Mail::Sympa::Error, 'must login first')
    end
  end

  describe '#am_i?' do
    before { login_sympa }

    it 'responds to am_i? method' do
      expect(sympa).to respond_to(:am_i?)
    end

    it 'has amI alias' do
      expect(sympa).to respond_to(:amI)
    end

    it 'returns a boolean result' do
      ensure_list_exists(test_list)
      result = sympa.am_i?(test_user, test_list)
      expect([true, false]).to include(result)
    end

    it 'accepts function parameter' do
      ensure_list_exists(test_list)
      result = sympa.am_i?(test_user, test_list, 'owner')
      expect([true, false]).to include(result)
    end

    it 'validates function parameter' do
      expect { sympa.am_i?(test_user, test_list, 'bogus') }.to raise_error(Mail::Sympa::Error)
    end

    it 'requires login' do
      new_sympa = Mail::Sympa.new(endpoint)
      expect { new_sympa.am_i?(test_user, test_list) }.to raise_error(Mail::Sympa::Error, 'must login first')
    end
  end

  describe '#add' do
    before { login_sympa }

    it 'responds to add method' do
      expect(sympa).to respond_to(:add)
    end

    it 'returns a boolean result' do
      ensure_list_exists(test_list)
      result = sympa.add('test@example.com', test_list, 'Test User')
      expect([true, false]).to include(result)
    end

    it 'requires at least three arguments' do
      expect { sympa.add }.to raise_error(ArgumentError)
      expect { sympa.add('test@example.com') }.to raise_error(ArgumentError)
      expect { sympa.add('test@example.com', test_list) }.to raise_error(ArgumentError)
    end

    it 'requires login' do
      new_sympa = Mail::Sympa.new(endpoint)
      expect { new_sympa.add('test@example.com', test_list, 'Test') }.to raise_error(Mail::Sympa::Error, 'must login first')
    end
  end

  describe '#del' do
    before { login_sympa }

    it 'responds to del method' do
      expect(sympa).to respond_to(:del)
    end

    it 'has delete alias' do
      expect(sympa).to respond_to(:delete)
    end

    it 'returns a boolean result' do
      ensure_list_exists(test_list)
      result = sympa.del('test@example.com', test_list)
      expect([true, false]).to include(result)
    end

    it 'requires at least two arguments' do
      expect { sympa.del }.to raise_error(ArgumentError)
      expect { sympa.del('test@example.com') }.to raise_error(ArgumentError)
    end

    it 'requires login' do
      new_sympa = Mail::Sympa.new(endpoint)
      expect { new_sympa.del('test@example.com', test_list) }.to raise_error(Mail::Sympa::Error, 'must login first')
    end
  end

  describe '#subscribe' do
    before { login_sympa }

    it 'responds to subscribe method' do
      expect(sympa).to respond_to(:subscribe)
    end

    it 'returns a boolean result' do
      ensure_list_exists(test_list)
      result = sympa.subscribe(test_list, 'Test User')
      expect([true, false]).to include(result)
    end

    it 'requires at least one argument' do
      expect { sympa.subscribe }.to raise_error(ArgumentError)
    end

    it 'requires login' do
      new_sympa = Mail::Sympa.new(endpoint)
      expect { new_sympa.subscribe(test_list) }.to raise_error(Mail::Sympa::Error, 'must login first')
    end
  end

  describe '#signoff' do
    before { login_sympa }

    it 'responds to signoff method' do
      expect(sympa).to respond_to(:signoff)
    end

    it 'has unsubscribe alias' do
      expect(sympa).to respond_to(:unsubscribe)
    end

    it 'returns a boolean result' do
      ensure_list_exists(test_list)
      result = sympa.signoff(test_list)
      expect([true, false]).to include(result)
    end

    it 'requires exactly one argument' do
      expect { sympa.signoff }.to raise_error(ArgumentError)
      expect { sympa.signoff(test_list, 'extra') }.to raise_error(ArgumentError)
    end

    it 'requires login' do
      new_sympa = Mail::Sympa.new(endpoint)
      expect { new_sympa.signoff(test_list) }.to raise_error(Mail::Sympa::Error, 'must login first')
    end
  end

  describe '#create_list' do
    before { login_sympa }

    it 'responds to create_list method' do
      expect(sympa).to respond_to(:create_list)
    end

    it 'has createList alias' do
      expect(sympa).to respond_to(:createList)
    end

    it 'returns a boolean result' do
      list_name = "test-#{Time.now.to_i}"
      result = sympa.create_list(list_name, 'Test List')
      expect([true, false]).to include(result)
    end

    it 'requires at least two arguments' do
      expect { sympa.create_list }.to raise_error(ArgumentError)
      expect { sympa.create_list("test-#{Time.now.to_i}") }.to raise_error(ArgumentError)
    end

    it 'requires login' do
      new_sympa = Mail::Sympa.new(endpoint)
      expect { new_sympa.create_list('test', 'Test') }.to raise_error(Mail::Sympa::Error, 'must login first')
    end
  end

  describe '#close_list' do
    before { login_sympa }

    it 'responds to close_list method' do
      expect(sympa).to respond_to(:close_list)
    end

    it 'has closeList alias' do
      expect(sympa).to respond_to(:closeList)
    end

    it 'returns a boolean result' do
      list_name = "test-#{Time.now.to_i}"
      sympa.create_list(list_name, 'Test List')
      result = sympa.close_list(list_name)
      expect([true, false]).to include(result)
    end

    it 'requires exactly one argument' do
      expect { sympa.close_list }.to raise_error(ArgumentError)
      expect { sympa.close_list('list1', 'list2') }.to raise_error(ArgumentError)
    end

    it 'requires login' do
      new_sympa = Mail::Sympa.new(endpoint)
      expect { new_sympa.close_list('test') }.to raise_error(Mail::Sympa::Error, 'must login first')
    end
  end

  describe '#authenticate_remote_app_and_run' do
    it 'responds to authenticate_remote_app_and_run method' do
      expect(sympa).to respond_to(:authenticate_remote_app_and_run)
    end

    it 'has authenticateRemoteAppAndRun alias' do
      expect(sympa).to respond_to(:authenticateRemoteAppAndRun)
    end

    it 'requires exactly five arguments' do
      expect { sympa.authenticate_remote_app_and_run }.to raise_error(ArgumentError)
      expect { sympa.authenticate_remote_app_and_run('A') }.to raise_error(ArgumentError)
      expect { sympa.authenticate_remote_app_and_run('A', 'B') }.to raise_error(ArgumentError)
      expect { sympa.authenticate_remote_app_and_run('A', 'B', 'C') }.to raise_error(ArgumentError)
      expect { sympa.authenticate_remote_app_and_run('A', 'B', 'C', 'D') }.to raise_error(ArgumentError)
      expect { sympa.authenticate_remote_app_and_run('A', 'B', 'C', 'D', 'E', 'F') }.to raise_error(ArgumentError)
    end
  end

  describe 'aliases' do
    it 'has url alias for endpoint' do
      expect(sympa).to respond_to(:url)
      expect(sympa.url).to eq(sympa.endpoint)
    end
  end
end
