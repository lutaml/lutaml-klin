# frozen_string_literal: true

require "lutaml"

module Lutaml
  module Klin
    module Repositories
      # Adapter for Lutaml::UmlRepository::Repository
      #
      # Provides a thin wrapper around the Repository API from the lutaml
      # gem, adapting it for lutaml-klin's needs. This adapter is purely for
      # delegation - no business logic should be added here.
      #
      # @example Load and query UML repository
      #   adapter = UmlRepositoryAdapter.new("plateau.lur")
      #   package = adapter.find_package("ModelRoot::i-UR::urf")
      #   classes = adapter.classes_in_package(package.qualified_name)
      #   feature_types = adapter.find_classes_by_stereotype("featureType")
      class UmlRepositoryAdapter
        # @return [Lutaml::UmlRepository::Repository] the underlying repository
        attr_reader :repository

        # Initialize adapter with a LUR package
        #
        # @param lur_path [String] Path to .lur package file
        # @raise [Errno::ENOENT] if LUR file not found
        # @raise [RuntimeError] if LUR package is invalid
        def initialize(lur_path)
          @repository = Lutaml::UmlRepository::Repository.from_package(lur_path)
        rescue Errno::ENOENT => e
          raise Errno::ENOENT, "LUR package not found: #{lur_path} - #{e.message}"
        rescue StandardError => e
          raise "Failed to load LUR package '#{lur_path}': #{e.message}"
        end

        # Find package by UML path
        #
        # @param path [String] UML package path (e.g.,
        #   "ModelRoot::i-UR::urf")
        # @return [Lutaml::Uml::Package, nil] the package or nil if not found
        def find_package(path)
          repository.find_package(path)
        rescue StandardError => e
          raise "Error finding package '#{path}': #{e.message}"
        end

        # Find class by qualified name
        #
        # @param qualified_name [String] Fully qualified class name
        #   (e.g., "ModelRoot::i-UR::urf::Building")
        # @return [Lutaml::Uml::Class, nil] the class or nil if not found
        def find_class(qualified_name)
          repository.find_class(qualified_name)
        rescue StandardError => e
          raise "Error finding class '#{qualified_name}': #{e.message}"
        end

        # Get classes in a package
        #
        # @param package_path [String] UML package path
        # @param recursive [Boolean] whether to include subpackages
        # @return [Array<Lutaml::Uml::Class>] list of classes
        def classes_in_package(package_path, recursive: false)
          repository.classes_in_package(package_path, recursive: recursive)
        rescue StandardError => e
          raise "Error getting classes in package '#{package_path}': " \
                "#{e.message}"
        end

        # Get enums in a package
        #
        # @param package_path [String] UML package path
        # @param recursive [Boolean] whether to include subpackages
        # @return [Array<Lutaml::Uml::Enum>] list of enums
        def enums_in_package(package_path, recursive: false)
          repository.enums_in_package(package_path, recursive: recursive)
        rescue StandardError => e
          raise "Error getting enums in package '#{package_path}': " \
                "#{e.message}"
        end

        # Find classes by stereotype
        #
        # @param stereotype [String] Stereotype name (e.g., "featureType")
        # @return [Array<Lutaml::Uml::Class>] classes with the stereotype
        def find_classes_by_stereotype(stereotype)
          repository.find_classes_by_stereotype(stereotype)
        rescue StandardError => e
          raise "Error finding classes by stereotype '#{stereotype}': " \
                "#{e.message}"
        end

        # Get all packages in the repository
        #
        # @return [Array] All packages
        def all_packages
          repository.list_packages("ModelRoot", recursive: true)
        rescue StandardError => e
          raise "Error retrieving packages: #{e.message}"
        end

        # Get repository statistics
        #
        # @return [Hash] statistics including:
        #   - :total_packages - number of packages
        #   - :total_classes - number of classes
        #   - :classes_by_stereotype - classes grouped by stereotype
        def statistics
          repository.statistics
        rescue StandardError => e
          raise "Error retrieving repository statistics: #{e.message}"
        end
      end
    end
  end
end