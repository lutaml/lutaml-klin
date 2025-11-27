#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to build PLATEAU LXR packages for testing
# This script automates the creation of LXR schema repositories from PLATEAU XSD files

require "pathname"
require "fileutils"

class PlateauLxrBuilder
  attr_reader :project_root, :config_file, :output_file

  def initialize
    @project_root = Pathname.new(__dir__).parent
    @config_file = @project_root.join("examples/plateau_schemas_config.yaml")
    @output_file = @project_root.join("packages/plateau_schemas.lxr")
  end

  def run
    print_header
    validate_prerequisites
    ensure_directories
    build_lxr_package
    verify_package
    print_success
  rescue StandardError => e
    print_error(e)
    exit(1)
  end

  private

  def print_header
    puts "=" * 80
    puts "  PLATEAU LXR Package Builder"
    puts "=" * 80
    puts ""
    puts "Configuration: #{config_file}"
    puts "Output:        #{output_file}"
    puts ""
  end

  def validate_prerequisites
    puts "Validating prerequisites..."

    # Check if lutaml-xsd is available
    unless system("which lutaml-xsd > /dev/null 2>&1")
      raise "lutaml-xsd command not found. Install with: gem install lutaml-xsd"
    end

    # Check if config file exists
    unless File.exist?(config_file)
      raise "Configuration file not found: #{config_file}"
    end

    puts "✓ Prerequisites validated"
    puts ""
  end

  def ensure_directories
    # Create packages directory if it doesn't exist
    packages_dir = project_root.join("packages")
    FileUtils.mkdir_p(packages_dir) unless File.directory?(packages_dir)
  end

  def build_lxr_package
    puts "Building PLATEAU LXR package..."
    puts ""

    # Build command
    cmd = [
      "lutaml-xsd", "package", "build", config_file.to_s,
      "--output", output_file.to_s,
      "--name", "PLATEAU Schema Repository",
      "--version", "3.2",
      "--description", "i-UR Urban Function and Object schemas with dependencies",
      "--verbose"
    ]

    puts "Executing: #{cmd.join(' ')}"
    puts ""

    # Execute command and capture output
    success = system(*cmd)

    raise "LXR package build failed" unless success

    puts ""
    puts "✓ LXR package created successfully"
  end

  def verify_package
    puts ""
    puts "Verifying package..."

    unless File.exist?(output_file)
      raise "Package file not found: #{output_file}"
    end

    file_size = File.size(output_file)
    raise "Package file is empty" if file_size.zero?

    puts "✓ Package verified:"
    puts "  - File: #{output_file}"
    puts "  - Size: #{format_bytes(file_size)}"
    puts ""

    # Get package info
    puts "Package information:"
    system("lutaml-xsd", "package", "info", output_file.to_s)
  end

  def print_success
    puts ""
    puts "=" * 80
    puts "  ✅  PLATEAU LXR Package Built Successfully"
    puts "=" * 80
    puts ""
    puts "Package location: #{output_file}"
    puts ""
    puts "Next steps:"
    puts "  1. Test with: bin/lutaml-klin process --lur <lur-file> --auto-lxr"
    puts "  2. Run integration tests: bundle exec rspec spec/integration/"
    puts ""
  end

  def print_error(error)
    puts ""
    puts "=" * 80
    puts "  ❌  Build Failed"
    puts "=" * 80
    puts ""
    puts "Error: #{error.message}"
    puts ""
    puts error.backtrace.join("\n") if ENV["DEBUG"]
  end

  def format_bytes(bytes)
    if bytes < 1024
      "#{bytes} bytes"
    elsif bytes < 1024 * 1024
      "#{(bytes / 1024.0).round(2)} KB"
    else
      "#{(bytes / (1024.0 * 1024)).round(2)} MB"
    end
  end
end

# Run the builder
PlateauLxrBuilder.new.run if __FILE__ == $PROGRAM_NAME
