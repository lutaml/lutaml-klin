# frozen_string_literal: true

require "fileutils"
# Repository adapters loaded on-demand when workflow executes
# require_relative "../repositories/uml_repository_adapter"
# require_relative "../repositories/schema_repository_adapter"
require_relative "../domain/services/package_filter"
require_relative "../domain/processing_result"
require_relative "mapping_workflow"
require_relative "validation_workflow"
require_relative "spa_workflow"

module Lutaml
  module Klin
    module Application
      # ProcessingWorkflow orchestrates the complete UML-to-XSD mapping process.
      #
      # This is the main application workflow that coordinates all phases:
      # 1. Loading UML and XSD repositories from LUR/LXR packages
      # 2. Loading ShapeChange configuration
      # 3. Filtering packages based on user patterns
      # 4. Generating mappings via MappingWorkflow
      # 5. Validating mappings via ValidationWorkflow (optional)
      # 6. Generating SPA via SpaWorkflow (optional)
      # 7. Returning comprehensive ProcessingResult
      #
      # The workflow follows these principles:
      # - **Atomic operation** - all outputs from same resolution pass
      # - **Pure orchestration** - delegates to specialized workflows
      # - **I/O handling** - manages all file operations
      # - **Error handling** - comprehensive error reporting
      # - **Progress tracking** - optional progress callbacks
      #
      # @example Basic usage
      #   workflow = ProcessingWorkflow.new
      #   result = workflow.execute(
      #     lur_path: "model.lur",
      #     lxr_path: "schemas.lxr",
      #     config_path: "config.xml",
      #     package_filter: "ModelRoot::i-UR::**",
      #     output_path: "output/"
      #   )
      #
      # @example With all options
      #   workflow = ProcessingWorkflow.new(
      #     progress_callback: ->(stage, msg) { puts "[#{stage}] #{msg}" }
      #   )
      #
      #   result = workflow.execute(
      #     lur_path: "model.lur",
      #     lxr_path: "schemas.lxr",
      #     config_path: "config.xml",
      #     package_filter: "**",
      #     output_path: "output/",
      #     type_overrides_path: "overrides.yaml",
      #     generate_mappings: true,
      #     generate_spa: true,
      #     validate: true,
      #     verbose: true
      #   )
      class ProcessingWorkflow
        # @return [Proc, nil] Optional progress callback
        attr_reader :progress_callback

        # Create a new ProcessingWorkflow.
        #
        # @param progress_callback [Proc, nil] Optional callback for progress
        #   updates. Receives (stage, message)
        def initialize(progress_callback: nil)
          @progress_callback = progress_callback
        end

        # Execute the complete processing workflow.
        #
        # @param lur_path [String] Path to LUR package file
        # @param lxr_path [String] Path to LXR package file
        # @param config_path [String] Path to ShapeChange configuration XML
        # @param package_filter [String] Package filter pattern (default: "**")
        # @param output_path [String] Output directory path
        # @param type_overrides_path [String, nil] Optional type overrides YAML
        # @param generate_mappings [Boolean] Generate YAML mappings
        #   (default: true)
        # @param generate_spa [Boolean] Generate SPA website (default: true)
        # @param validate [Boolean] Generate validation reports (default: true)
        # @param verbose [Boolean] Enable verbose output (default: false)
        # @return [Domain::ProcessingResult] The processing result
        #
        # @raise [RuntimeError] if processing fails
        def execute(lur_path:, lxr_path:, config_path:,
                    package_filter: "**", output_path: "_site",
                    type_overrides_path: nil,
                    generate_mappings: true, generate_spa: true,
                    spa_data_mode: :embedded,
                    validate: true, verbose: false)
          start_time = Time.now

          # Step 1: Load repositories
          report_progress(:loading, "Loading UML and XSD repositories...")
          uml_repo, xsd_repo = load_repositories(lur_path, lxr_path)

          # Step 2: Load configuration
          report_progress(:config, "Loading ShapeChange configuration...")
          config, type_overrides = load_configuration(
            config_path,
            type_overrides_path
          )

          # Step 3: Parse and apply package filter
          report_progress(:filtering,
                          "Filtering packages with pattern: #{package_filter}")
          packages = filter_packages(uml_repo, package_filter)

          if packages.empty?
            # Provide helpful error with available packages
            all_packages = uml_repo.all_packages
            available_info = all_packages.map do |pkg|
              simple_name = pkg.name.split("::").last
              "#{simple_name} (#{pkg.name})"
            end

            error_msg = <<~ERROR
              No packages matched filter pattern: #{package_filter}

              Available packages:
              #{available_info.join("\n")}

              Suggestions:
              1. Use simple names: --packages "uro,urf,CityGML2.0"
              2. Use full paths: --packages "Conceptual Models::i-UR::Urban Planning ADE 3.2::uro"
              3. Use wildcards: --packages "**::uro,**::urf,**::CityGML*"
              4. Use regex: --packages "/.*CityGML.*/"
              5. Process all: --packages "**"
            ERROR

            raise error_msg
          end

          # Show matched packages in verbose mode
          if verbose
            matched_info = packages.map do |pkg|
              simple_name = pkg.name.split("::").last
              class_count = uml_repo.classes_in_package(pkg.name).size
              "#{simple_name} → #{pkg.name} (#{class_count} classes)"
            end

            report_progress(
              :filtering,
              "Matched #{packages.size} package(s):\n#{matched_info.join("\n")}"
            )
          else
            report_progress(
              :filtering,
              "Selected #{packages.size} package(s) for processing"
            )
          end

          # Step 4: Generate mappings
          report_progress(:mapping, "Generating UML-to-XSD mappings...")
          schema_mapping = generate_mappings(
            packages,
            uml_repo,
            xsd_repo,
            config,
            type_overrides,
            verbose: verbose
          )

          # Track output paths
          output_paths = {}

          # Step 5: Save mappings if requested
          if generate_mappings
            report_progress(:saving, "Saving mapping files...")
            mapping_paths = save_mappings(schema_mapping, output_path)
            output_paths[:mappings] = mapping_paths
          end

          # Step 6: Validate mappings if requested
          validation_result = nil
          if validate
            report_progress(:validation, "Validating mappings...")
            validation_result = validate_mappings(
              schema_mapping,
              output_path
            )
            output_paths[:validation] = validation_result[:report_paths]
          end

          # Step 7: Generate SPA if requested
          if generate_spa
            report_progress(:spa, "Generating SPA website...")
            spa_path = generate_spa_site(
              schema_mapping,
              output_path,
              data_mode: spa_data_mode
            )
            output_paths[:spa] = spa_path
          end

          # Calculate statistics
          # Note: calculate_statistics returns string keys, convert to symbols
          stats_with_strings = schema_mapping.calculate_statistics
          statistics = stats_with_strings.transform_keys(&:to_sym)
          statistics[:resolution_rate] = schema_mapping.resolution_rate
          statistics[:processing_time] = (Time.now - start_time).round(2)

          # Build metadata
          metadata = {
            lur_path: lur_path,
            lxr_path: lxr_path,
            config_path: config_path,
            package_filter: package_filter,
            packages_processed: packages.map(&:name)
          }

          # Create and return result
          result = Domain::ProcessingResult.new(
            schema_mapping: schema_mapping,
            validation_result: validation_result&.dig(:result),
            output_paths: output_paths,
            statistics: statistics,
            metadata: metadata
          )

          report_progress(:complete, "Processing complete!")
          result
        rescue StandardError => e
          report_progress(:error, "Processing failed: #{e.message}")
          raise
        end

        private

        # Report progress to the callback if set.
        #
        # @param stage [Symbol] Current processing stage
        # @param message [String] Progress message
        def report_progress(stage, message)
          progress_callback&.call(stage, message)
        end

        # Load UML and XSD repositories.
        #
        # @param lur_path [String] Path to LUR package
        # @param lxr_path [String] Path to LXR package
        # @return [Array<UmlRepositoryAdapter, SchemaRepositoryAdapter>]
        def load_repositories(lur_path, lxr_path)
          # Lazy load repository adapters
          require_relative "../repositories/uml_repository_adapter"
          require_relative "../repositories/schema_repository_adapter"

          unless File.exist?(lur_path)
            raise "LUR package not found: #{lur_path}"
          end
          unless File.exist?(lxr_path)
            raise "LXR package not found: #{lxr_path}"
          end

          uml_repo = Repositories::UmlRepositoryAdapter.new(lur_path)
          xsd_repo = Repositories::SchemaRepositoryAdapter.new(lxr_path)

          [uml_repo, xsd_repo]
        end

        # Load ShapeChange configuration and optional type overrides.
        #
        # @param config_path [String] Path to ShapeChange config XML
        # @param type_overrides_path [String, nil] Optional overrides YAML
        # @return [Array<Object, Hash>] Configuration and overrides
        def load_configuration(config_path, type_overrides_path)
          unless File.exist?(config_path)
            raise "Configuration file not found: #{config_path}"
          end

          # Load ShapeChange config
          # Note: Actual implementation would parse XML config
          # For now, we'll use a simple placeholder
          config = load_shapechange_config(config_path)

          # Load type overrides if provided
          type_overrides = {}
          if type_overrides_path && File.exist?(type_overrides_path)
            require "yaml"
            type_overrides = YAML.load_file(type_overrides_path) || {}
          end

          [config, type_overrides]
        end

        # Load ShapeChange configuration from XML file.
        #
        # @param config_path [String] Path to config XML
        # @return [Shapechange::ShapeChangeConfiguration] Configuration object
        def load_shapechange_config(config_path)
          parser = Shapechange::ConfigParser.new
          parser.parse_file(config_path)
        rescue StandardError => e
          raise "Failed to load ShapeChange configuration: #{e.message}"
        end

        # Filter packages based on pattern.
        #
        # @param uml_repo [UmlRepositoryAdapter] The UML repository
        # @param filter_pattern [String] The filter pattern
        # @return [Array] Filtered packages
        def filter_packages(uml_repo, filter_pattern)
          package_filter = Domain::Services::PackageFilter.new(filter_pattern)

          # Get all packages from repository
          all_packages = uml_repo.all_packages

          # Apply filter using 'name' attribute (lutaml packages use :name not :qualified_name)
          package_filter.filter_packages(all_packages, path_method: :name)
        end

        # Generate mappings for filtered packages.
        #
        # @param packages [Array] UML packages to process
        # @param uml_repo [UmlRepositoryAdapter] UML repository
        # @param xsd_repo [SchemaRepositoryAdapter] XSD repository
        # @param config [Object] ShapeChange configuration
        # @param type_overrides [Hash] Type override mappings
        # @param verbose [Boolean] Enable verbose output
        # @return [Mapping::SchemaMapping] The schema mapping
        def generate_mappings(packages, uml_repo, xsd_repo, config,
                              type_overrides, verbose: false)
          workflow = MappingWorkflow.new(
            uml_repository: uml_repo,
            xsd_repository: xsd_repo,
            shapechange_config: config,
            type_overrides: type_overrides
          )

          # Generate mappings for each package
          package_paths = packages.map(&:name)
          schema_mapping = workflow.generate_mappings_for_packages(
            package_paths,
            verbose: verbose
          )

          # Set source tracking
          schema_mapping.set_timestamp!

          # Set traceability metadata (Phase 2 enhancement)
          set_traceability_metadata(schema_mapping, uml_repo, xsd_repo)

          schema_mapping
        end

        # Set comprehensive traceability metadata
        #
        # @param schema_mapping [Mapping::SchemaMapping] The schema mapping
        # @param uml_repo [UmlRepositoryAdapter] UML repository
        # @param xsd_repo [SchemaRepositoryAdapter] XSD repository
        def set_traceability_metadata(schema_mapping, uml_repo, xsd_repo)
          traceability = {
            resolution_strategies: %w[
              TypeOverrideStrategy
              ShapeChangeStrategy
              SchemaRepositoryStrategy
            ]
          }

          # Add LXR package info if available
          if xsd_repo.respond_to?(:package_metadata)
            traceability[:lxr_package_info] = xsd_repo.package_metadata
          end

          # Add LUR package info if available
          if uml_repo.respond_to?(:package_metadata)
            traceability[:lur_package_info] = uml_repo.package_metadata
          end

          schema_mapping.set_traceability(traceability)
        end

        # Save mappings to YAML files.
        #
        # @param schema_mapping [Mapping::SchemaMapping] The schema mapping
        # @param output_path [String] Base output directory
        # @return [Array<String>] Paths to saved mapping files
        def save_mappings(schema_mapping, output_path)
          mappings_dir = File.join(output_path, "mappings")
          FileUtils.mkdir_p(mappings_dir)

          saved_paths = []

          # Save overall schema mapping
          overall_path = File.join(mappings_dir, "schema_mapping.yaml")
          File.write(overall_path, schema_mapping.to_yaml)
          saved_paths << overall_path

          # Save individual package mappings
          schema_mapping.package_mappings.each do |pkg_mapping|
            # Derive filename from package name
            filename = pkg_mapping.uml_package_name
                                  .split("::")
                                  .last
                                  .downcase
                                  .gsub(/[^a-z0-9_]/, "_") + ".yaml"

            pkg_path = File.join(mappings_dir, filename)
            File.write(pkg_path, pkg_mapping.to_yaml)
            saved_paths << pkg_path
          end

          saved_paths
        end

        # Validate mappings and generate reports.
        #
        # @param schema_mapping [Mapping::SchemaMapping] The schema mapping
        # @param output_path [String] Base output directory
        # @return [Hash] Hash with :result and :report_paths
        def validate_mappings(schema_mapping, output_path)
          workflow = ValidationWorkflow.new

          validation_dir = File.join(output_path, "validation")
          FileUtils.mkdir_p(validation_dir)

          report_base = File.join(validation_dir, "validation_report")
          workflow.validate_and_report(schema_mapping, report_base)
        end

        # Generate SPA website.
        #
        # @param schema_mapping [Mapping::SchemaMapping] The schema mapping
        # @param output_path [String] Base output directory
        # @param data_mode [Symbol] Data mode: :embedded or :linked
        # @return [String] Path to SPA directory
        def generate_spa_site(schema_mapping, output_path, data_mode: :embedded)
          workflow = SpaWorkflow.new

          spa_dir = File.join(output_path, "spa")
          workflow.generate_spa(
            schema_mapping,
            spa_dir,
            data_mode: data_mode
          )
        end
      end
    end
  end
end
