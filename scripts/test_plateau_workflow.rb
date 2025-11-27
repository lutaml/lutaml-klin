#!/usr/bin/env ruby
# frozen_string_literal: true

# Manual test script for PLATEAU workflow
# Tests the complete workflow: XMI + ShapeChange configs → LXR packages → YAML mappings

require "pathname"
require "fileutils"
require "benchmark"
require "yaml"

class PlateauWorkflowTester
  attr_reader :project_root, :results

  # Test configuration
  LUR_PACKAGE = "packages/plateau_all.lur"
  SHAPECHANGE_URO = "reference/shapechange-configs/ShapeChangeConfig_Plateau_urf.xml"
  SHAPECHANGE_URF = "reference/shapechange-configs/ShapeChangeConfig_Plateau_urf.xml"
  OUTPUT_DIR = "tmp/plateau_workflow_test"

  def initialize
    @project_root = Pathname.new(__dir__).parent
    @results = []
  end

  def run_all_tests
    print_header
    setup_test_environment

    test_lxr_creation
    test_uro_processing
    test_urf_processing
    test_cache_performance
    test_output_validation

    print_summary
    cleanup_if_needed
  end

  private

  def print_header
    puts "=" * 80
    puts "  PLATEAU Workflow Integration Test"
    puts "=" * 80
    puts ""
    puts "This test validates the complete PLATEAU workflow:"
    puts "  1. LXR package creation from ShapeChange configs"
    puts "  2. URO package processing with auto-LXR"
    puts "  3. URF package processing with auto-LXR"
    puts "  4. Cache performance validation"
    puts "  5. Output YAML validation"
    puts ""
    puts "=" * 80
    puts ""
  end

  def setup_test_environment
    puts "Setting up test environment..."

    # Clean previous test outputs
    FileUtils.rm_rf(project_root.join(OUTPUT_DIR))
    FileUtils.mkdir_p(project_root.join(OUTPUT_DIR))

    puts "✓ Test environment ready"
    puts ""
  end

  def test_lxr_creation
    puts "=" * 80
    puts "Test 1: LXR Package Creation"
    puts "=" * 80
    puts ""

    lxr_output = project_root.join("tmp/test_plateau.lxr")

    time = Benchmark.realtime do
      cmd = [
        "bin/lutaml-klin", "create-lxr",
        "--shapechange", project_root.join(SHAPECHANGE_URO).to_s,
        "--output", lxr_output.to_s,
        "--verbose"
      ]

      puts "Executing: #{cmd.join(' ')}"
      puts ""

      system(*cmd)
    end

    status = if File.exist?(lxr_output) && File.size(lxr_output).positive?
               "PASS"
             else
               "FAIL"
             end

    @results << {
      test: "LXR Creation",
      time: time,
      status: status,
      details: status == "PASS" ? "Package size: #{format_bytes(File.size(lxr_output))}" : "Package not created"
    }

    puts ""
    puts "#{status == 'PASS' ? '✓' : '✗'} Test 1: #{status} (#{time.round(2)}s)"
    puts ""
  end

  def test_uro_processing
    puts "=" * 80
    puts "Test 2: URO Package Processing"
    puts "=" * 80
    puts ""

    skip_reason = check_prerequisites(SHAPECHANGE_URO, LUR_PACKAGE)
    if skip_reason
      @results << {
        test: "URO Processing",
        time: 0,
        status: "SKIP",
        details: skip_reason
      }
      puts "⊘ Test 2: SKIPPED - #{skip_reason}"
      puts ""
      return
    end

    output_dir = project_root.join(OUTPUT_DIR, "uro")

    time = Benchmark.realtime do
      cmd = [
        "bin/lutaml-klin", "process",
        "--lur", project_root.join(LUR_PACKAGE).to_s,
        "--shapechange", project_root.join(SHAPECHANGE_URO).to_s,
        "--auto-lxr",
        "--output", output_dir.to_s,
        "--verbose"
      ]

      puts "Executing: #{cmd.join(' ')}"
      puts ""

      system(*cmd)
    end

    yaml_files = Dir.glob("#{output_dir}/**/*.yaml")
    status = if yaml_files.any?
               "PASS"
             else
               "FAIL"
             end

    @results << {
      test: "URO Processing",
      time: time,
      status: status,
      details: status == "PASS" ? "Generated #{yaml_files.size} YAML files" : "No YAML files generated"
    }

    puts ""
    puts "#{status == 'PASS' ? '✓' : '✗'} Test 2: #{status} (#{time.round(2)}s)"
    puts ""
  end

  def test_urf_processing
    puts "=" * 80
    puts "Test 3: URF Package Processing"
    puts "=" * 80
    puts ""

    skip_reason = check_prerequisites(SHAPECHANGE_URF, LUR_PACKAGE)
    if skip_reason
      @results << {
        test: "URF Processing",
        time: 0,
        status: "SKIP",
        details: skip_reason
      }
      puts "⊘ Test 3: SKIPPED - #{skip_reason}"
      puts ""
      return
    end

    output_dir = project_root.join(OUTPUT_DIR, "urf")

    time = Benchmark.realtime do
      cmd = [
        "bin/lutaml-klin", "process",
        "--lur", project_root.join(LUR_PACKAGE).to_s,
        "--shapechange", project_root.join(SHAPECHANGE_URF).to_s,
        "--auto-lxr",
        "--output", output_dir.to_s,
        "--verbose"
      ]

      puts "Executing: #{cmd.join(' ')}"
      puts ""

      system(*cmd)
    end

    yaml_files = Dir.glob("#{output_dir}/**/*.yaml")
    status = if yaml_files.any?
               "PASS"
             else
               "FAIL"
             end

    @results << {
      test: "URF Processing",
      time: time,
      status: status,
      details: status == "PASS" ? "Generated #{yaml_files.size} YAML files" : "No YAML files generated"
    }

    puts ""
    puts "#{status == 'PASS' ? '✓' : '✗'} Test 3: #{status} (#{time.round(2)}s)"
    puts ""
  end

  def test_cache_performance
    puts "=" * 80
    puts "Test 4: Cache Performance (Second Run)"
    puts "=" * 80
    puts ""

    skip_reason = check_prerequisites(SHAPECHANGE_URO, LUR_PACKAGE)
    if skip_reason
      @results << {
        test: "Cached Processing",
        time: 0,
        status: "SKIP",
        details: skip_reason
      }
      puts "⊘ Test 4: SKIPPED - #{skip_reason}"
      puts ""
      return
    end

    output_dir = project_root.join(OUTPUT_DIR, "uro_cached")

    puts "Running second URO processing to test cache..."
    puts ""

    time = Benchmark.realtime do
      cmd = [
        "bin/lutaml-klin", "process",
        "--lur", project_root.join(LUR_PACKAGE).to_s,
        "--shapechange", project_root.join(SHAPECHANGE_URO).to_s,
        "--auto-lxr",
        "--output", output_dir.to_s,
        "--verbose"
      ]

      system(*cmd)
    end

    # Cached run should be faster (< 5 seconds is good)
    status = if time < 10.0
               "PASS"
             else
               "SLOW"
             end

    @results << {
      test: "Cached Processing",
      time: time,
      status: status,
      details: "Second run completed in #{time.round(2)}s"
    }

    puts ""
    puts "#{status == 'PASS' ? '✓' : '⚠'} Test 4: #{status} (#{time.round(2)}s)"
    puts ""
  end

  def test_output_validation
    puts "=" * 80
    puts "Test 5: Output YAML Validation"
    puts "=" * 80
    puts ""

    output_dir = project_root.join(OUTPUT_DIR)

    unless Dir.exist?(output_dir)
      @results << {
        test: "YAML Validation",
        time: 0,
        status: "SKIP",
        details: "No output directory found"
      }
      puts "⊘ Test 5: SKIPPED - No output directory"
      puts ""
      return
    end

    yaml_files = Dir.glob("#{output_dir}/**/*.yaml")

    valid_count = 0
    invalid_count = 0

    yaml_files.each do |file|
      content = YAML.load_file(file)

      # Basic validation
      if content.is_a?(Hash)
        valid_count += 1
      else
        invalid_count += 1
        puts "  ✗ Invalid structure: #{file}"
      end
    rescue StandardError => e
      invalid_count += 1
      puts "  ✗ Parse error in #{file}: #{e.message}"
    end

    status = if invalid_count.zero? && valid_count.positive?
               "PASS"
             else
               "FAIL"
             end

    @results << {
      test: "YAML Validation",
      time: 0,
      status: status,
      details: "#{valid_count} valid, #{invalid_count} invalid out of #{yaml_files.size} files"
    }

    puts ""
    puts "Validated #{yaml_files.size} YAML files:"
    puts "  ✓ Valid: #{valid_count}"
    puts "  ✗ Invalid: #{invalid_count}"
    puts ""
    puts "#{status == 'PASS' ? '✓' : '✗'} Test 5: #{status}"
    puts ""
  end

  def check_prerequisites(*files)
    files.each do |file|
      path = project_root.join(file)
      return "Required file not found: #{file}" unless File.exist?(path)
    end
    nil
  end

  def print_summary
    puts "=" * 80
    puts "  Test Summary"
    puts "=" * 80
    puts ""

    @results.each do |result|
      symbol = case result[:status]
               when "PASS" then "✓"
               when "FAIL" then "✗"
               when "SKIP" then "⊘"
               when "SLOW" then "⚠"
               else "?"
               end

      time_str = result[:time].positive? ? " (#{result[:time].round(2)}s)" : ""
      puts "#{symbol} #{result[:test]}: #{result[:status]}#{time_str}"
      puts "  #{result[:details]}" if result[:details]
    end

    puts ""

    passed = @results.count { |r| r[:status] == "PASS" }
    failed = @results.count { |r| r[:status] == "FAIL" }
    skipped = @results.count { |r| r[:status] == "SKIP" }
    total = @results.size

    puts "Results: #{passed} passed, #{failed} failed, #{skipped} skipped (#{total} total)"

    total_time = @results.sum { |r| r[:time] }
    puts "Total execution time: #{total_time.round(2)}s"

    puts ""
    puts "=" * 80
    puts ""
  end

  def cleanup_if_needed
    # Optional: ask user if they want to keep test outputs
    print "Keep test outputs? (y/n) [y]: "
    response = gets.chomp.downcase

    if response == "n"
      puts "Cleaning up test outputs..."
      FileUtils.rm_rf(project_root.join(OUTPUT_DIR))
      FileUtils.rm_rf(project_root.join("tmp/test_plateau.lxr"))
      puts "✓ Cleanup complete"
    else
      puts "Test outputs preserved in: #{OUTPUT_DIR}"
    end
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

# Run tests
PlateauWorkflowTester.new.run_all_tests if __FILE__ == $PROGRAM_NAME
