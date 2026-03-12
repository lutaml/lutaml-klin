# frozen_string_literal: true

require "thor"
require_relative "commands/generate_command"
require_relative "commands/xsd_generate_command"
require_relative "commands/merge_command"
require_relative "commands/validate_command"
require_relative "commands/report_command"
require_relative "commands/process_command"
require_relative "commands/create_lxr_command"
require_relative "commands/spa_command"
require_relative "application/lookup_workflow"

module Lutaml
  module Klin
    # Command-line interface for Lutaml::Klin
    class Cli < Thor
      class_option :verbose, type: :boolean, default: false,
                             desc: "Enable verbose output"

      desc "generate CONFIG XMI XSD_DIR OUTPUT",
           "Generate UML-XSD mapping from ShapeChange config, XMI, and XSD files"
      long_desc <<~DESC
        Generates a YAML mapping file showing relationships between UML models
        and XSD schemas.

        CONFIG: Path to ShapeChange configuration XML file
        XMI: Path to XMI file containing UML model
        XSD_DIR: Directory containing XSD schema files
        OUTPUT: Path for output YAML mapping file

        Example:
          lutaml-klin generate config.xml model.xmi schemas/ output.yaml
      DESC
      option :package, type: :string, required: true,
                       desc: "UML package name to process"
      option :encoding_rule, type: :string,
                             desc: "Encoding rule to use (default: auto-detect)"
      option :type_mapping, type: :string,
                            desc: "Path to type override mapping YAML file"
      def generate(config_path, xmi_path, xsd_dir, output_path)
        Commands::GenerateCommand.new(
          config_path: config_path,
          xmi_path: xmi_path,
          xsd_dir: xsd_dir,
          output_path: output_path,
          package: options[:package],
          encoding_rule: options[:encoding_rule],
          type_mapping_path: options[:type_mapping],
          verbose: options[:verbose]
        ).run
      end

      desc "merge INPUT_FILES OUTPUT",
           "Merge multiple mapping YAML files into one"
      long_desc <<~DESC
        Merges multiple YAML mapping files into a single consolidated file.

        INPUT_FILES: Space-separated list of input YAML files
        OUTPUT: Path for merged output YAML file

        Example:
          lutaml-klin merge mapping1.yaml mapping2.yaml merged.yaml
      DESC
      def merge(*args)
        if args.length < 2
          say "Error: At least one input file and one output file required",
              :red
          exit 1
        end

        output_path = args.pop
        input_files = args

        Commands::MergeCommand.new(
          input_files: input_files,
          output_path: output_path,
          verbose: options[:verbose]
        ).run
      end

      desc "validate MAPPING_FILE",
           "Validate a mapping YAML file"
      long_desc <<~DESC
        Validates the structure and content of a mapping YAML file.

        MAPPING_FILE: Path to mapping YAML file to validate

        Example:
          lutaml-klin validate mapping.yaml
      DESC
      option :schema, type: :string,
                      desc: "Optional JSON schema for validation"
      def validate(mapping_file)
        Commands::ValidateCommand.new(
          mapping_file: mapping_file,
          schema: options[:schema],
          verbose: options[:verbose]
        ).run
      end

      desc "report MAPPING_FILE",
           "Generate human-readable transformation report from mapping YAML"
      long_desc <<~DESC
        Generates a detailed investigation report showing UML-to-XSD
        transformation patterns and relationships.

        MAPPING_FILE: Path to mapping YAML file

        The report includes:
        - UML class details (stereotypes, attributes, inheritance)
        - XSD element and type definitions
        - Transformation patterns observed
        - Cardinality mappings

        Example:
          lutaml-klin report mapping.yaml
          lutaml-klin report mapping.yaml --output report.txt
      DESC
      option :output, type: :string,
                      desc: "Output file for report (default: stdout)"
      def report(mapping_file)
        Commands::ReportCommand.new(
          mapping_file: mapping_file,
          output_file: options[:output],
          verbose: options[:verbose]
        ).run
      end

      desc "lookup IDENTIFIER",
           "Lookup UML-to-XSD or XSD-to-UML mapping"
      long_desc <<~DESC
        Performs bidirectional lookup of UML and XSD mappings.
        Auto-detects direction based on identifier format.

        IDENTIFIER: UML class/attribute name or XSD type/element name

        Examples:
          lutaml-klin lookup "ModelRoot::i-UR::urf::UrbanPlanningArea" --mapping mapping.yaml
          lutaml-klin lookup "gml:CodeType" --mapping mapping.yaml
          lutaml-klin lookup "UrbanPlanningArea::areaType" --mapping mapping.yaml --fuzzy
      DESC
      option :mapping, type: :string, required: true,
                       desc: "Path to mapping YAML file"
      option :type, type: :string, default: "auto",
                    desc: "Lookup type: class, attribute, xsd-type, xsd-element, or auto"
      option :direction, type: :string, default: "auto",
                         desc: "Direction: uml-to-xsd, xsd-to-uml, or auto (detect)"
      option :format, type: :string, default: "text",
                      desc: "Output format: text, json, yaml"
      option :fuzzy, type: :boolean, default: false,
                     desc: "Enable fuzzy matching"
      def lookup(identifier)
        workflow = Application::LookupWorkflow.new(options[:mapping])

        # Determine lookup type
        lookup_type = case options[:type].downcase
                      when "class" then :class
                      when "attribute" then :attribute
                      when "xsd-type" then :type
                      when "xsd-element" then :element
                      else :auto
                      end

        # Perform lookup based on direction
        result = case options[:direction].downcase
                 when "uml-to-xsd"
                   workflow.lookup_uml_to_xsd(identifier, type: lookup_type,
                                                          fuzzy: options[:fuzzy])
                 when "xsd-to-uml"
                   workflow.lookup_xsd_to_uml(identifier, type: lookup_type,
                                                          fuzzy: options[:fuzzy])
                 else
                   workflow.auto_lookup(identifier, fuzzy: options[:fuzzy])
                 end

        # Format and display result
        output_format = options[:format].to_sym
        output = workflow.format_result(result, format: output_format)
        puts output
      rescue StandardError => e
        say "Error: #{e.message}", :red
        exit 1
      end

      desc "lookup-uml IDENTIFIER",
           "Find XSD mapping for UML element"
      long_desc <<~DESC
        Finds XSD mappings for a UML class or attribute.

        IDENTIFIER: UML class name or attribute in format "ClassName::attributeName"

        Examples:
          lutaml-klin lookup-uml "ModelRoot::i-UR::urf::UrbanPlanningArea" --mapping mapping.yaml
          lutaml-klin lookup-uml "UrbanPlanningArea::areaType" --mapping mapping.yaml
      DESC
      option :mapping, type: :string, required: true,
                       desc: "Path to mapping YAML file"
      option :format, type: :string, default: "text",
                      desc: "Output format: text, json, yaml"
      option :fuzzy, type: :boolean, default: false,
                     desc: "Enable fuzzy matching"
      def lookup_uml(identifier)
        workflow = Application::LookupWorkflow.new(options[:mapping])
        result = workflow.lookup_uml_to_xsd(identifier, fuzzy: options[:fuzzy])
        output = workflow.format_result(result, format: options[:format].to_sym)
        puts output
      rescue StandardError => e
        say "Error: #{e.message}", :red
        exit 1
      end

      desc "lookup-xsd IDENTIFIER",
           "Find UML elements mapped to XSD type/element"
      long_desc <<~DESC
        Finds UML elements that map to a given XSD type or element.

        IDENTIFIER: XSD type or element name (with namespace prefix if applicable)

        Examples:
          lutaml-klin lookup-xsd "gml:CodeType" --mapping mapping.yaml
          lutaml-klin lookup-xsd "urf:UrbanPlanningAreaType" --mapping mapping.yaml
      DESC
      option :mapping, type: :string, required: true,
                       desc: "Path to mapping YAML file"
      option :format, type: :string, default: "text",
                      desc: "Output format: text, json, yaml"
      option :fuzzy, type: :boolean, default: false,
                     desc: "Enable fuzzy matching"
      def lookup_xsd(identifier)
        workflow = Application::LookupWorkflow.new(options[:mapping])
        result = workflow.lookup_xsd_to_uml(identifier, fuzzy: options[:fuzzy])
        output = workflow.format_result(result, format: options[:format].to_sym)
        puts output
      rescue StandardError => e
        say "Error: #{e.message}", :red
        exit 1
      end

      desc "interactive-lookup",
           "Start interactive lookup session"
      long_desc <<~DESC
        Starts an interactive lookup session where you can perform
        multiple lookups without restarting the command.

        Example:
          lutaml-klin interactive-lookup --mapping mapping.yaml
      DESC
      option :mapping, type: :string, required: true,
                       desc: "Path to mapping YAML file"
      def interactive_lookup
        workflow = Application::LookupWorkflow.new(options[:mapping])
        workflow.interactive_lookup
      rescue StandardError => e
        say "Error: #{e.message}", :red
        exit 1
      end

      desc "process", "Complete UML-to-XSD mapping workflow"
      long_desc <<~DESC
        Process UML and XSD repositories to generate comprehensive mappings,
        validation reports, and interactive SPA website in a single operation.

        Supports two modes:
        1. Manual: Provide pre-built LUR and LXR packages
        2. Auto-LXR: Automatically create LXR from ShapeChange config

        Examples:
          # Manual mode with pre-built packages
          lutaml-klin process \\
            --lur plateau_uml.lur \\
            --lxr plateau_schemas.lxr \\
            --config config/shapechange.xml \\
            --packages "ModelRoot::i-UR::**" \\
            --output output/

          # Auto-LXR mode (automatic LXR creation from ShapeChange config)
          lutaml-klin process \\
            --lur plateau_uml.lur \\
            --shapechange config.xml \\
            --auto-lxr \\
            --packages "ModelRoot::i-UR::**" \\
            --output output/

          # Force rebuild cached LXR
          lutaml-klin process \\
            --lur model.lur \\
            --shapechange config.xml \\
            --auto-lxr \\
            --force-rebuild \\
            --output output/

          # With type overrides
          lutaml-klin process \\
            --lur model.lur \\
            --lxr schemas.lxr \\
            --config config.xml \\
            --packages "**" \\
            --output output/ \\
            --type-overrides overrides.yaml

          # Use vanilla JavaScript template instead of Alpine.js
          lutaml-klin process \\
            --lur model.lur \\
            --lxr schemas.lxr \\
            --config config.xml \\
            --packages "**" \\
            --spa-template-type vanilla \\
            --output output/

          # Verbose mode shows cache hits/misses
          lutaml-klin process \\
            --lur model.lur \\
            --shapechange config.xml \\
            --auto-lxr \\
            --verbose \\
            --output output/
      DESC
      option :lur, required: true, desc: "Path to LUR package file (.lur)"
      option :lxr, desc: "Path to LXR package file (.lxr)"
      option :shapechange,
             desc: "Path to ShapeChange config (for auto-LXR or process)"
      option :config,
             desc: "Path to ShapeChange configuration XML (legacy alias for --shapechange)"
      option :auto_lxr, type: :boolean, default: false,
                        desc: "Automatically create LXR from ShapeChange config"
      option :lxr_cache_dir,
             desc: "Directory for cached LXR packages (default: .lutaml-klin/cache)"
      option :force_rebuild, type: :boolean, default: false,
                             desc: "Force rebuild of LXR even if cached"
      option :packages, default: "**",
                        desc: "Package filter pattern (e.g., 'i-UR::**')"
      option :output, default: "_site",
                      desc: "Output directory path (default: _site)"
      option :type_overrides, desc: "Path to type override YAML file"
      option :generate_mappings, type: :boolean, default: true,
                                 desc: "Generate YAML mappings"
      option :generate_spa, type: :boolean, default: true,
                            desc: "Generate SPA website"
      option :spa_template_type, default: "alpine",
                                 desc: "SPA template type: alpine (default) or vanilla"
      option :spa_data_mode, default: "embedded",
                             desc: "SPA data mode: embedded or linked"
      option :validate, type: :boolean, default: true,
                        desc: "Generate validation reports"
      def process
        # Validate options
        validate_process_options

        # Auto-create LXR if requested
        if options[:auto_lxr]
          require_relative "lxr/auto_builder"

          config_path = options[:shapechange] || options[:config]
          auto_builder = Lxr::AutoBuilder.new(
            config_path,
            cache_dir: options[:lxr_cache_dir],
            force_rebuild: options[:force_rebuild],
            verbose: options[:verbose]
          )

          # Build or use cached LXR
          options[:lxr] = auto_builder.build_or_use_existing
        end

        # Ensure config is set for ProcessCommand
        options[:config] ||= options[:shapechange]

        # Run process command
        command = Commands::ProcessCommand.new(options)
        command.run
      rescue StandardError => e
        say "Error: #{e.message}", :red
        say e.backtrace.first(5).join("\n") if options[:verbose]
        exit 1
      end

      private

      # Validate process command options
      def validate_process_options
        if options[:auto_lxr]
          # Auto-LXR mode requires ShapeChange config
          config_path = options[:shapechange] || options[:config]
          unless config_path
            raise ArgumentError,
                  "--shapechange (or --config) is required when using --auto-lxr"
          end
        else
          # Manual mode requires LXR package
          unless options[:lxr]
            raise ArgumentError,
                  "--lxr is required (or use --auto-lxr with --shapechange)"
          end

          # Also need config for ProcessCommand
          unless options[:config] || options[:shapechange]
            raise ArgumentError, "--config (or --shapechange) is required"
          end
        end
      end

      public

      desc "xsd", "Generate XSD schemas from UML model"
      long_desc <<~DESC
        Generate XSD schema files from a UML model in LUR package format,
        following ShapeChange encoding rules.

        This command reads a UML model from a LUR package and generates
        XSD schema files according to ShapeChange configuration.

        By default, a YAML mapping file is generated alongside each XSD file.
        Use --no-generate-mapping to disable this feature.

        Example:
          lutaml-klin xsd \\
            --lur packages/plateau_all.lur \\
            --config ShapeChangeConfig_Plateau_urf.xml \\
            --packages "uro,urf" \\
            --output schemas/

          # Disable YAML mapping generation
          lutaml-klin xsd \\
            --lur packages/plateau_all.lur \\
            --config ShapeChangeConfig_Plateau_urf.xml \\
            --packages "uro" \\
            --output schemas/ \\
            --no-generate-mapping
      DESC
      option :lur, required: true, desc: "Path to LUR package file"
      option :config, required: true,
                      desc: "Path to ShapeChange configuration XML"
      option :packages,
             desc: "Package names to process (comma-separated, default: all)"
      option :output, default: "schemas", desc: "Output directory for XSD files"
      option :generate_mapping, type: :boolean, default: true,
                                desc: "Generate YAML mapping file alongside XSD (default: true)"
      def xsd
        Commands::XsdGenerateCommand.new(options).run
      end

      desc "create-lxr OUTPUT_PATH",
           "Create LXR package from ShapeChange config or XSD files"
      long_desc <<~DESC
        Create an LXR (LutaML XSD Repository) package from either:
        - ShapeChange configuration file (extracts XSD locations and namespaces)
        - XSD files directory with namespace configuration

        Examples:
          # From ShapeChange config
          lutaml-klin create-lxr output.lxr --shapechange config.xml

          # From XSD directory with namespace config
          lutaml-klin create-lxr output.lxr --xsd-dir schemas/ --namespaces ns.yaml

          # With custom package metadata
          lutaml-klin create-lxr output.lxr --shapechange config.xml \\
            --name "PLATEAU Schemas" --version "5.0.0" \\
            --description "PLATEAU v5.0 XSD schemas"

          # With validation
          lutaml-klin create-lxr output.lxr --shapechange config.xml --validate --verbose
      DESC
      option :shapechange, type: :string,
                           desc: "Path to ShapeChange configuration file"
      option :xsd_dir, type: :string,
                       desc: "Directory containing XSD files"
      option :namespaces, type: :string,
                          desc: "YAML file with namespace mappings"
      option :xsd_mode, type: :string, default: "include_all",
                        enum: %w[include_all allow_external],
                        desc: "XSD bundling mode"
      option :resolution_mode, type: :string, default: "resolved",
                               enum: %w[resolved bare],
                               desc: "Resolution mode"
      option :format, type: :string, default: "marshal",
                      enum: %w[marshal json yaml parse],
                      desc: "Serialization format"
      option :name, type: :string,
                    desc: "Package name"
      option :version, type: :string,
                       desc: "Package version"
      option :description, type: :string,
                           desc: "Package description"
      option :validate, type: :boolean, default: false,
                        desc: "Validate package after creation"
      def create_lxr(output_path)
        command = Commands::CreateLxrCommand.new(options.merge(output: output_path))
        command.run
      rescue StandardError => e
        say "Error: #{e.message}", :red
        exit 1
      end

      desc "spa", "Generate SPA from mapping file(s)"
      long_desc <<~DESC
        Generate an interactive Single Page Application (SPA) for browsing
        UML-to-XSD mappings from one or more pre-existing mapping YAML files.

        This is Process 3 in the standard workflow:
          1. Generate XSD + Mapping (lutaml-klin xsd)
          2. Create Complete LXR (lutaml-xsd package composition)
          3. Generate SPA (lutaml-klin spa) ← This command

        The SPA provides:
        - Interactive package tree navigation
        - Real-time search across classes and attributes
        - Resolution status filtering
        - Deep linking support
        - Responsive design for desktop and mobile

        Multi-Schema Support:
        - When multiple --mapping files are provided, the SPA shows how
          the same UML model maps to different XSD schemas side-by-side
        - Perfect for comparing URO vs URF schemas, different versions, etc.

        Template Types:
        - Alpine.js (default): Modern reactive UI with automatic updates
        - Vanilla JS: Traditional JavaScript with zero dependencies

        Examples:
          # Single schema (basic usage)
          lutaml-klin spa \\
            --mapping urbanObject_mapping.yaml \\
            --output spa/

          # Multi-schema comparison (URO + URF)
          lutaml-klin spa \\
            --mapping urbanObject_mapping.yaml \\
            --mapping urbanFunction_mapping.yaml \\
            --output spa/

          # Generate with vanilla JavaScript template
          lutaml-klin spa \\
            --mapping urbanObject_mapping.yaml \\
            --output spa/ \\
            --template-type vanilla

          # With custom title
          lutaml-klin spa \\
            --mapping urbanObject_mapping.yaml \\
            --mapping urbanFunction_mapping.yaml \\
            --output spa/ \\
            --title "PLATEAU URO vs URF Comparison"

          # For HTTP server deployment (linked data)
          lutaml-klin spa \\
            --mapping urbanObject_mapping.yaml \\
            --output spa/ \\
            --data-mode linked
      DESC
      option :mapping, type: :array, required: true,
                       desc: "Path(s) to mapping YAML file(s) - specify multiple times for multi-schema comparison"
      option :output, type: :string, required: true,
                      desc: "Output directory for SPA"
      option :template_type, type: :string, default: "alpine",
                             enum: %w[alpine vanilla],
                             desc: "SPA template type (alpine or vanilla)"
      option :data_mode, type: :string, default: "embedded",
                         enum: %w[embedded linked],
                         desc: "Data mode (embedded for file://, linked for http://)"
      option :title, type: :string,
                     desc: "Custom SPA title (optional)"
      def spa
        command = Commands::SpaCommand.new(options)
        command.run
      rescue StandardError => e
        say "Error: #{e.message}", :red
        say e.backtrace.first(5).join("\n"), :red if options[:verbose]
        exit 1
      end

      desc "version", "Show lutaml-klin version"
      def version
        say "lutaml-klin version #{Lutaml::Klin::VERSION}"
      end

      def self.exit_on_failure?
        true
      end
    end
  end
end
