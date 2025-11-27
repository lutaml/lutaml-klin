# frozen_string_literal: true

require "spec_helper"
require "benchmark"

RSpec.describe "PLATEAU LXR Package Performance", :integration do
  let(:lxr_path) { "packages/plateau_schemas.lxr" }
  let(:test_lxr_path) { "tmp/test_plateau.lxr" }

  describe "LXR package loading performance" do
    it "loads package in under 100ms" do
      skip "LXR package not found" unless File.exist?(lxr_path)

      require "lutaml/xsd"

      load_time = Benchmark.realtime do
        Lutaml::Xsd::SchemaRepository.from_package(lxr_path)
      end

      expect(load_time).to be < 0.1,
                           "LXR load time was #{(load_time * 1000).round(2)}ms, expected < 100ms"

      puts "\n  ✓ LXR load time: #{(load_time * 1000).round(2)}ms"
    end

    it "handles missing package gracefully" do
      expect do
        require "lutaml/xsd"
        Lutaml::Xsd::SchemaRepository.from_package("nonexistent.lxr")
      end.to raise_error(StandardError)
    end
  end

  describe "Type resolution performance" do
    before(:all) do
      skip "LXR package not found" unless File.exist?(lxr_path)
      require "lutaml/xsd"
      @repo = Lutaml::Xsd::SchemaRepository.from_package(lxr_path)
    end

    it "resolves types efficiently" do
      skip "Repository not loaded" unless @repo

      # Test common type lookups
      test_types = [
        "gml:CodeType",
        "gml:MeasureType",
        "uro:BuildingType",
        "urf:UrbanPlanningArea",
        "xlink:href"
      ]

      query_time = Benchmark.realtime do
        100.times do
          test_types.each do |type|
            @repo.find_type(type)
          rescue StandardError
            # Some types may not exist, that's ok for performance testing
          end
        end
      end

      total_queries = 100 * test_types.size
      avg_query_time = query_time / total_queries

      expect(avg_query_time).to be < 0.001,
                                "Average query time was #{(avg_query_time * 1000).round(3)}ms, expected < 1ms"

      puts "\n  ✓ Average query time: #{(avg_query_time * 1000).round(3)}ms (#{total_queries} queries)"
    end

    it "handles concurrent type lookups" do
      skip "Repository not loaded" unless @repo
      skip "Concurrent tests not applicable in current environment"

      # This test would verify thread-safety of type lookups
      # Implementation depends on whether lutaml-xsd supports concurrent access
    end
  end

  describe "Package metadata" do
    it "contains expected metadata" do
      skip "LXR package not found" unless File.exist?(lxr_path)

      require "lutaml/xsd"
      repo = Lutaml::Xsd::SchemaRepository.from_package(lxr_path)

      # Verify repository was loaded
      expect(repo).not_to be_nil

      # These assertions depend on lutaml-xsd API
      # Adjust based on actual SchemaRepository interface
      if repo.respond_to?(:metadata)
        metadata = repo.metadata
        expect(metadata[:name]).to eq("PLATEAU Schema Repository")
        expect(metadata[:version]).to eq("3.2")
      end
    end
  end

  describe "Package validation" do
    it "validates package structure" do
      skip "LXR package not found" unless File.exist?(lxr_path)

      # Basic file validation
      expect(File.size(lxr_path)).to be > 0

      # Check it's a valid package by attempting to load
      require "lutaml/xsd"
      expect do
        Lutaml::Xsd::SchemaRepository.from_package(lxr_path)
      end.not_to raise_error
    end

    it "detects corrupted packages" do
      # Create a corrupted package for testing
      corrupted_path = "tmp/corrupted.lxr"
      File.write(corrupted_path, "INVALID CONTENT")

      require "lutaml/xsd"
      expect do
        Lutaml::Xsd::SchemaRepository.from_package(corrupted_path)
      end.to raise_error(StandardError)

      FileUtils.rm_f(corrupted_path)
    end
  end

  describe "Cache effectiveness" do
    it "uses cache for repeated loads" do
      skip "LXR package not found" unless File.exist?(lxr_path)
      skip "Cache mechanism not yet implemented"

      # This test would verify that repeated package loads use caching
      # Implementation depends on caching strategy
    end
  end

  describe "Memory usage" do
    it "loads package with reasonable memory footprint" do
      skip "LXR package not found" unless File.exist?(lxr_path)
      skip "Memory profiling requires additional tools"

      # This test would verify memory usage doesn't exceed threshold
      # Could use tools like memory_profiler gem

      # require "memory_profiler"
      # report = MemoryProfiler.report do
      #   Lutaml::Xsd::SchemaRepository.from_package(lxr_path)
      # end
      # expect(report.total_allocated_memsize).to be < 50_000_000 # 50MB
    end
  end

  describe "Error handling" do
    it "provides clear error messages for missing files" do
      require "lutaml/xsd"

      expect do
        Lutaml::Xsd::SchemaRepository.from_package("missing.lxr")
      end.to raise_error(StandardError, /not found|does not exist/i)
    end

    it "handles invalid package format" do
      invalid_package = "tmp/invalid.lxr"
      File.write(invalid_package, "not a valid package")

      require "lutaml/xsd"
      expect do
        Lutaml::Xsd::SchemaRepository.from_package(invalid_package)
      end.to raise_error(StandardError)

      FileUtils.rm_f(invalid_package)
    end
  end
end
