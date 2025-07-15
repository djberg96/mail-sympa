#!/usr/bin/env ruby

require_relative 'lib/mail/sympa'

puts "Testing Mail::Sympa with Savon..."

begin
  # Create instance
  sympa = Mail::Sympa.new('http://localhost:8080/sympasoap')
  puts "✓ Created Mail::Sympa instance"

  # Test login
  cookie = sympa.login('postmaster@localhost', 'test')
  puts "✓ Login successful, cookie: #{cookie}"

  # Test lists
  lists = sympa.lists
  puts "✓ Got lists: #{lists.inspect} (#{lists.class})"

  # Test info (if available)
  begin
    info = sympa.info('testlist')
    puts "✓ Got info: #{info.inspect} (#{info.class})"
  rescue => e
    puts "! Info error: #{e.message}"
  end

  # Test review (if available)
  begin
    review = sympa.review('testlist')
    puts "✓ Got review: #{review.inspect} (#{review.class})"
  rescue => e
    puts "! Review error: #{e.message}"
  end

  puts "\nBasic tests completed!"

rescue => e
  puts "✗ Error: #{e.class}: #{e.message}"
  puts e.backtrace.join("\n")
end
