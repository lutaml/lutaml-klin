#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "lutaml"

xmi_path = "/Users/mulgogi/src/mn/mn-samples-plateau/sources/xmi/20251022-uro.xmi"

puts "Parsing XMI file: #{xmi_path}"
doc = Lutaml::Parser.parse([File.new(xmi_path)])

puts "\n=== Document Class ==="
puts doc.class

puts "\n=== Document Methods ==="
puts doc.methods.grep(/package/).sort

puts "\n=== Document Instance Variables ==="
puts doc.instance_variables

puts "\n=== Trying to access packages ==="
if doc.respond_to?(:packages)
  puts "doc.packages: #{doc.packages.inspect}"
else
  puts "doc does not respond to :packages"
end

puts "\n=== Trying to access models ==="
if doc.respond_to?(:models)
  puts "doc.models: #{doc.models.inspect}"
else
  puts "doc does not respond to :models"
end

puts "\n=== Trying various accessors ==="
%i[package model root_model root_package elements xmi_root].each do |method|
  if doc.respond_to?(method)
    result = doc.send(method)
    puts "doc.#{method}: #{result.class} - #{result.inspect[0..200]}"
  end
end

puts "\n=== Document Inspection ==="
puts doc.inspect[0..500]
