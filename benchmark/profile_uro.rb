#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "ruby-prof"

# Add lib to load path
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "lutaml/klin/cli"

# Profile URO package generation
RubyProf.start

# Simulate CLI execution
ARGV.replace([
               "xsd",
               "--lur", "spec/fixtures/packages/plateau_all.lur",
               "--config", "examples/ShapeChangeConfig_Plateau_uro.xml",
               "--output", "tmp/profile_output",
               "--packages", "uro"
             ])

begin
  Lutaml::Klin::Cli.start(ARGV)
rescue SystemExit
  # Ignore exit
end

result = RubyProf.stop

# Print flat profile
printer = RubyProf::FlatPrinter.new(result)
printer.print($stdout, min_percent: 1)