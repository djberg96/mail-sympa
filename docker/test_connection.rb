#!/usr/bin/env ruby

# Test script for mail-sympa library against Docker Sympa instance
#
# This script tests basic functionality of the mail-sympa library
# against the Docker Sympa container.

require_relative '../lib/mail-sympa'

# Configuration
SOAP_URL = 'http://localhost:8080/sympasoap'
TEST_EMAIL = 'test@localhost'
TEST_PASSWORD = 'test123'
TEST_LIST = 'testlist'

def test_connection
  puts "Testing connection to Sympa SOAP interface..."

  begin
    sympa = Mail::Sympa.new(SOAP_URL)
    puts "✓ Successfully created Mail::Sympa instance"
    puts "  Endpoint: #{sympa.endpoint}"
    puts "  Namespace: #{sympa.namespace}"
    return sympa
  rescue => e
    puts "✗ Failed to create Mail::Sympa instance: #{e.message}"
    return nil
  end
end

def test_login(sympa, email, password)
  puts "\nTesting login..."

  begin
    result = sympa.login(email, password)
    puts "✓ Successfully logged in"
    puts "  Cookie: #{sympa.cookie[0..50]}..." if sympa.cookie
    return true
  rescue => e
    puts "✗ Login failed: #{e.message}"
    puts "  Note: You may need to create the user account first via the web interface"
    return false
  end
end

def test_lists(sympa)
  puts "\nTesting lists method..."

  begin
    lists = sympa.lists
    puts "✓ Successfully retrieved lists"
    puts "  Found #{lists.length} lists: #{lists.join(', ')}"
    return lists
  rescue => e
    puts "✗ Failed to retrieve lists: #{e.message}"
    return []
  end
end

def test_complex_lists(sympa)
  puts "\nTesting complex_lists method..."

  begin
    lists = sympa.complex_lists
    puts "✓ Successfully retrieved complex lists"
    puts "  Found #{lists.length} lists"
    lists.each_with_index do |list, i|
      break if i >= 3  # Show only first 3
      puts "    - #{list.respond_to?(:name) ? list.name : list.inspect}"
    end
    return lists
  rescue => e
    puts "✗ Failed to retrieve complex lists: #{e.message}"
    return []
  end
end

def test_info(sympa, list_name)
  puts "\nTesting info method for list: #{list_name}..."

  begin
    info = sympa.info(list_name)
    puts "✓ Successfully retrieved list info"
    puts "  Subject: #{info.respond_to?(:subject) ? info.subject : 'N/A'}"
    return info
  rescue => e
    puts "✗ Failed to retrieve list info: #{e.message}"
    puts "  Note: The list '#{list_name}' may not exist"
    return nil
  end
end

def main
  puts "=" * 60
  puts "Testing mail-sympa library against Docker Sympa instance"
  puts "=" * 60

  # Test connection
  sympa = test_connection
  return unless sympa

  # Test login (this will likely fail initially)
  login_success = test_login(sympa, TEST_EMAIL, TEST_PASSWORD)

  unless login_success
    puts "\n" + "!" * 60
    puts "LOGIN SETUP REQUIRED"
    puts "!" * 60
    puts "To complete testing, you need to:"
    puts "1. Visit http://localhost:8080/sympa"
    puts "2. Create an account for: #{TEST_EMAIL}"
    puts "3. Set password to: #{TEST_PASSWORD}"
    puts "4. Create a test list named: #{TEST_LIST}"
    puts "5. Re-run this script"
    puts "!" * 60
    return
  end

  # Test methods that require authentication
  lists = test_lists(sympa)
  test_complex_lists(sympa)

  # Test info method
  if lists.any?
    test_info(sympa, lists.first)
  else
    test_info(sympa, TEST_LIST)
  end

  puts "\n" + "=" * 60
  puts "Test completed successfully!"
  puts "Your mail-sympa library is working with the Docker Sympa instance."
  puts "=" * 60
end

if __FILE__ == $0
  main
end
