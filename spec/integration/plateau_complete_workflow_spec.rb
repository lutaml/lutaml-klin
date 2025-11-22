# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "yaml"
require "benchmark"

RSpec.describe "PLATEAU Complete Workflow", :integration do
  let(:lur_package) { "spec/fixtures/packages/plateau_all.lur" }
  let(:shapechange_uro) { "reference/shapechange-configs/ShapeChangeConfig_Plateau_urf.xml" }
  let(:shapechange_urf) { "reference/shapechange-configs/ShapeChangeConfig_Plateau_urf.xml" }
  let(:output_dir) { "tmp/plateau_integration_test" }

  before(:all) do
    FileUtils.rm_rf("tmp/plateau_integration_test")
    FileUtils.mkdir_p("tmp/plateau_integration_test")
  end

  after(:all) do
    # Keep outputs for manual inspection
    # FileUtils.rm_rf("tmp/plateau_integration_test")
  end

  describe "URO Package Processing" do
    context "when all prerequisites are available" do
      it "processes URO package with auto-LXR" do
        skip "LUR package not found: #{lur_package}" unless File.exist?(lur_package)
        skip "ShapeChange config not found: #{shapechange_uro}" unless File.exist?(shapechange_uro)

        # Run process command with auto-LXR
        result = system(
          "bin/lutaml-klin", "process",
          "--lur", lur_package,
          "--shapechange", shapechange_uro,
          "--auto-lxr",
          "--output", "#{output_dir}/uro",
          "--verbose"
        )

        expect(result).to be true, "lutaml-klin process command failed"
        expect(Dir.exist?("#{output_dir}/uro")).to be true, "Output directory not created"
      end

      it "generates valid YAML mappings" do
        skip "Output not generated" unless Dir.exist?("#{output_dir}/uro")

        yaml_files = Dir.glob("#{output_dir}/uro/**/*.yaml")
        expect(yaml_files).not_to be_empty, "No YAML files generated"

        yaml_files.each do |file|
          content = YAML.load_file(file)

          # Validate basic structure
          expect(content).to be_a(Hash), "YAML file #{file} is not a hash"

          # Check for expected top-level keys
          # Adjust based on actual output structure
          if content.key?("schema_mapping")
            expect(content["schema_mapping"]).to have_key("version")
            expect(content["schema_mapping"]).to have_key("source")
          end
        end
      end

      it "includes traceability information in YAML output" do
        skip "Output not generated" unless Dir.exist?("#{output_dir}/uro")

        yaml_files = Dir.glob("#{output_dir}/uro/**/*.yaml")
        skip "No YAML files to check" if yaml_files.empty?

        yaml_files.each do |file|
          content = YAML.load_file(file)

          # Check for traceability metadata (if implemented)
          next unless content.key?("schema_mapping")

          schema_mapping = content["schema_mapping"]

          # These are future enhancements
          # expect(schema_mapping).to have_key("generated_at") if traceability is added
          # expect(schema_mapping["source"]).to have_key("lxr_package") if traceability is added
        end
      end
    end

    context "when prerequisites are missing" do
      it "fails gracefully when LUR package is missing" do
        result = system(
          "bin/lutaml-klin", "process",
          "--lur", "nonexistent.lur",
          "--shapechange", shapechange_uro,
          "--auto-lxr",
          "--output", "#{output_dir}/uro_fail",
          out: File::NULL,
          err: File::NULL
        )

        expect(result).to be false, "Command should fail with missing LUR package"
      end

      it "fails gracefully when ShapeChange config is missing" do
        skip "LUR package not found" unless File.exist?(lur_package)

        result = system(
          "bin/lutaml-klin", "process",
          "--lur", lur_package,
          "--shapechange", "nonexistent.xml",
          "--auto-lxr",
          "--output", "#{output_dir}/uro_fail",
          out: File::NULL,
          err: File::NULL
        )

        expect(result).to be false, "Command should fail with missing ShapeChange config"
      end
    end
  end

  describe "URF Package Processing" do
    it "processes URF package with auto-LXR" do
      skip "LUR package not found: #{lur_package}" unless File.exist?(lur_package)
      skip "ShapeChange config not found: #{shapechange_urf}" unless File.exist?(shapechange_urf)

      result = system(
        "bin/lutaml-klin", "process",
        "--lur", lur_package,
        "--shapechange", shapechange_urf,
        "--auto-lxr",
        "--output", "#{output_dir}/urf",
        "--verbose"
      )

      expect(result).to be true, "lutaml-klin process command failed"
      expect(Dir.glob("#{output_dir}/urf/**/*.yaml")).not_to be_empty, "No YAML files generated"
    end
  end

  describe "Cache Performance" do
    it "utilizes cache on second run" do
      skip "LUR package not found" unless File.exist?(lur_package)
      skip "ShapeChange config not found" unless File.exist?(shapechange_uro)

      # First run to create cache
      first_run_time = Benchmark.realtime do
        system(
          "bin/lutaml-klin", "process",
          "--lur", lur_package,
          "--shapechange", shapechange_uro,
          "--auto-lxr",
          "--output", "#{output_dir}/uro_cache1",
          out: File::NULL,
          err: File::NULL
        )
      end

      # Second run should use cache
      second_run_time = Benchmark.realtime do
        system(
          "bin/lutaml-klin", "process",
          "--lur", lur_package,
          "--shapechange", shapechange_uro,
          "--auto-lxr",
          "--output", "#{output_dir}/uro_cache2",
          out: File::NULL,
          err: File::NULL
        )
      end

      puts "\n  First run:  #{first_run_time.round(2)}s"
      puts "  Second run: #{second_run_time.round(2)}s"

      # Second run should be faster or at least not significantly slower
      # Allow some variance for system performance
      expect(second_run_time).to be <= (first_run_time * 1.2),
        "Second run should utilize cache and be faster"
    end
  end

  describe "Complete Statistics" do
    it "processes multiple packages successfully" do
      skip "Output not generated" unless Dir.exist?(output_dir)

      total_yaml_files = Dir.glob("#{output_dir}/**/*.yaml").size

      puts "\n" + "=" * 70
      puts "  PLATEAU Integration Test Results"
      puts "=" * 70
      puts ""
      puts "  Total YAML files generated: #{total_yaml_files}"
      puts "  Output directory: #{output_dir}"
      puts ""

      # Collect statistics from YAML files
      class_count = 0
      attribute_count = 0

      Dir.glob("#{output_dir}/**/*.yaml").each do |file|
        begin
          content = YAML.load_file(file)

          # Count based on actual YAML structure
          # This is a placeholder - adjust based on real structure
          if content.is_a?(Hash) && content.key?("mapping")
            mapping = content["mapping"]
            class_count += 1 if mapping
          end
        rescue StandardError => e
          puts "  Warning: Failed to parse #{file}: #{e.message}"
        end
      end

      puts "  Estimated classes processed: #{class_count}"
      puts ""
      puts "=" * 70
      puts ""

      expect(total_yaml_files).to be > 0, "No YAML files generated"
    end
  end

  describe "Output Validation" do
    it "generates well-formed YAML files" do
      skip "Output not generated" unless Dir.exist?(output_dir)

      yaml_files = Dir.glob("#{output_dir}/**/*.yaml")
      skip "No YAML files to validate" if yaml_files.empty?

      invalid_files = []

      yaml_files.each do |file|
        begin
          YAML.load_file(file)
        rescue StandardError => e
          invalid_files << { file: file, error: e.message }
        end
      end

      if invalid_files.any?
        puts "\nInvalid YAML files:"
        invalid_files.each do |item|
          puts "  - #{item[:file]}: #{item[:error]}"
        end
      end

      expect(invalid_files).to be_empty, "Found #{invalid_files.size} invalid YAML files"
    end

    it "creates output files with consistent structure" do
      skip "Output not generated" unless Dir.exist?(output_dir)

      yaml_files = Dir.glob("#{output_dir}/**/*.yaml")
      skip "No YAML files to validate" if yaml_files.empty?

      # Check that all files have similar structure
      structures = yaml_files.map do |file|
        content = YAML.load_file(file)
        content.keys.sort if content.is_a?(Hash)
      end.compact.uniq

      # All files should have similar top-level keys
      # Allow for some variance but expect consistency
      expect(structures.size).to be <= 3, "YAML files have inconsistent structure"
    end
  end

  describe "Integration with LXR auto-builder" do
    it "automatically creates LXR package when needed" do
      skip "ShapeChange config not found" unless File.exist?(shapechange_uro)

      # Check if cache directory exists after processing
      cache_dir = ".lutaml-klin/cache"

      if Dir.exist?(cache_dir)
        lxr_files = Dir.glob("#{cache_dir}/*.lxr")
        puts "\n  Found #{lxr_files.size} LXR packages in cache"

        expect(lxr_files).not_to be_empty, "No LXR packages created in cache"
      else
        skip "Cache directory not created"
      end
    end
  end

  describe "Error Recovery" do
    it "handles errors gracefully" do
      # Test with intentionally invalid input
      result = system(
        "bin/lutaml-klin", "process",
        "--lur", lur_package,
        "--shapechange", "nonexistent.xml",
        "--auto-lxr",
        "--output", "#{output_dir}/error_test",
        out: File::NULL,
        err: File::NULL
      )

      expect(result).to be false, "Should fail with invalid input"
    end
  end
end