#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "benchmark"
require "fileutils"

# Benchmark XSD generation performance
class XsdGenerationBenchmark
  FIXTURE_LUR = "spec/fixtures/packages/plateau_all.lur"
  OUTPUT_DIR = "tmp/benchmark_output"

  BENCHMARKS = {
    uro: {
      name: "URO Package (255 classes, 324 elements, 487 types)",
      config: "examples/ShapeChangeConfig_Plateau_uro.xml",
      packages: "uro",
      expected_output: "urbanObject.xsd"
    },
    urf: {
      name: "URF Package (208 classes, 208 elements, 416 types)",
      config: "examples/ShapeChangeConfig_Plateau_urf.xml",
      packages: "urf",
      expected_output: "urbanFunction.xsd"
    }
  }.freeze

  def initialize
    @results = {}
    setup_output_directory
  end

  def run
    puts "=" * 80
    puts "LutaML Klin XSD Generation Benchmark"
    puts "=" * 80
    puts

    BENCHMARKS.each do |key, benchmark|
      run_benchmark(key, benchmark)
      puts
    end

    print_summary
  end

  private

  def setup_output_directory
    FileUtils.rm_rf(OUTPUT_DIR)
    FileUtils.mkdir_p(OUTPUT_DIR)
  end

  def run_benchmark(key, benchmark)
    puts "Benchmarking: #{benchmark[:name]}"
    puts "-" * 80

    command = build_command(benchmark)
    puts "Command: #{command}"
    puts

    # Warm-up run (not measured)
    puts "Warm-up run..."
    system(command, out: File::NULL, err: File::NULL)
    cleanup_output

    # Measured runs
    times = []
    runs = 3

    runs.times do |i|
      print "Run #{i + 1}/#{runs}... "

      time = Benchmark.realtime do
        system(command, out: File::NULL, err: File::NULL)
      end

      times << time
      puts "#{format('%.2f', time)}s"

      cleanup_output
    end

    # Calculate statistics
    avg_time = times.sum / times.size
    min_time = times.min
    max_time = times.max

    @results[key] = {
      name: benchmark[:name],
      times: times,
      avg: avg_time,
      min: min_time,
      max: max_time
    }

    puts
    puts "Average: #{format('%.2f', avg_time)}s"
    puts "Min: #{format('%.2f', min_time)}s"
    puts "Max: #{format('%.2f', max_time)}s"
  end

  def build_command(benchmark)
    [
      "bundle exec ruby -Ilib exe/lutaml-klin xsd",
      "--lur #{FIXTURE_LUR}",
      "--config #{benchmark[:config]}",
      "--output #{OUTPUT_DIR}",
      "--packages #{benchmark[:packages]}"
    ].join(" ")
  end

  def cleanup_output
    FileUtils.rm_rf(OUTPUT_DIR)
    FileUtils.mkdir_p(OUTPUT_DIR)
  end

  def print_summary
    puts "=" * 80
    puts "BENCHMARK SUMMARY"
    puts "=" * 80
    puts

    @results.each_value do |result|
      puts "#{result[:name]}:"
      puts "  Average: #{format('%.2f', result[:avg])}s"
      puts "  Range: #{format('%.2f', result[:min])}s - " \
           "#{format('%.2f', result[:max])}s"
      puts
    end

    # Performance targets
    puts "-" * 80
    puts "PERFORMANCE TARGETS (50% improvement):"
    puts "-" * 80

    if @results[:uro]
      uro_target = @results[:uro][:avg] * 0.5
      puts "URO: #{format('%.2f', @results[:uro][:avg])}s → " \
           "<#{format('%.2f', uro_target)}s"
    end

    if @results[:urf]
      urf_target = @results[:urf][:avg] * 0.5
      puts "URF: #{format('%.2f', @results[:urf][:avg])}s → " \
           "<#{format('%.2f', urf_target)}s"
    end

    puts
  end
end

# Run benchmark if executed directly
if __FILE__ == $PROGRAM_NAME
  XsdGenerationBenchmark.new.run
end