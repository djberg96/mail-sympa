#!/usr/bin/env ruby

require 'bundler/setup'
require_relative 'lib/mail-sympa'

# Test the response format
sympa = Mail::Sympa.new('http://localhost:8080/sympasoap')
sympa.login('postmaster@localhost', 'test')

puts "=== Testing complex_lists via public method ==="
result = sympa.complex_lists

puts "Final result from complex_lists:"
puts result.inspect
puts "Result class: #{result.class}"

if result.is_a?(Array) && result.first
  puts "\nFirst element:"
  puts result.first.inspect
  puts "First element class: #{result.first.class}"

  if result.first.respond_to?(:name)
    puts "First element name: #{result.first.name}"
  end

  if result.first.respond_to?(:subject)
    puts "First element subject: #{result.first.subject}"
  end
end
