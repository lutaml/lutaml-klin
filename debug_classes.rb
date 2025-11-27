# frozen_string_literal: true

require "bundler/setup"
require_relative "lib/lutaml/klin/xmi_navigator"

xmi_path = "/Users/mulgogi/src/mn/mn-samples-plateau/sources/xmi/20251022-uro.xmi"
navigator = Lutaml::Klin::XmiNavigator.new
navigator.parse_file(xmi_path)

uro_package = navigator.packages.find { |p| p.name =~ /uro/i }

if uro_package
  puts "Package found: #{uro_package.name}"
  puts "Package class: #{uro_package.class}"
  puts "Classes size: #{uro_package.classes.size}"
  puts "First class type: #{uro_package.classes.first.class}"
  puts "First class inspect: #{uro_package.classes.first.inspect}"

  if uro_package.classes.first.respond_to?(:name)
    puts "First class name: #{uro_package.classes.first.name}"
  else
    puts "First class (as string): #{uro_package.classes.first}"
  end
end
