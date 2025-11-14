# frozen_string_literal: true

require "lutaml/model"
require "lutaml/xsd"
require "moxml"

require_relative "klin/version"

# ShapeChange-specific components
require_relative "klin/shapechange/models/config/xml_namespace"
require_relative "klin/shapechange/models/config/xsd_map_entry"
require_relative "klin/shapechange/models/config/package_info"
require_relative "klin/shapechange/models/config/encoding_rule"
require_relative "klin/shapechange/models/config/shape_change_configuration"
require_relative "klin/shapechange/config_parser"
require_relative "klin/shapechange/xinclude_resolver"
require_relative "klin/shapechange/models/xsd_document"
require_relative "klin/shapechange/rule_registry"
require_relative "klin/shapechange/rule_checker"
require_relative "klin/shapechange/standard_rules"
require_relative "klin/shapechange/xsd_generator"

# Mapping models
require_relative "klin/models/mapping/attribute_mapping"
require_relative "klin/models/mapping/class_mapping"
require_relative "klin/models/mapping/package_mapping"
require_relative "klin/models/mapping/schema_mapping"

# UML models
require_relative "klin/models/uml/attribute"
require_relative "klin/models/uml/association"
require_relative "klin/models/uml/class"
require_relative "klin/models/uml/package"

# Repository adapters (loaded on-demand, not at require time)
# require_relative "klin/repositories/uml_repository_adapter"
# require_relative "klin/repositories/schema_repository_adapter"

# Domain - Resolution value objects
require_relative "klin/domain/resolution_result"
require_relative "klin/domain/resolution_context"
require_relative "klin/domain/validation_result"
require_relative "klin/domain/lookup_result"
require_relative "klin/domain/processing_result"

# Domain - Resolution strategies
require_relative "klin/domain/strategies/base_strategy"
require_relative "klin/domain/strategies/type_override_strategy"
require_relative "klin/domain/strategies/shapechange_strategy"
require_relative "klin/domain/strategies/schema_repository_strategy"

# Domain - Resolution engine
require_relative "klin/domain/resolution_engine"

# Domain - Services
require_relative "klin/domain/services/mapping_service"
require_relative "klin/domain/services/validation_service"
require_relative "klin/domain/services/lookup_service"
require_relative "klin/domain/services/spa_generator"
require_relative "klin/domain/services/package_filter"

# Domain - Reporters
require_relative "klin/domain/reporters/json_reporter"
require_relative "klin/domain/reporters/markdown_reporter"

# Application layer workflows
require_relative "klin/application/mapping_workflow"
require_relative "klin/application/validation_workflow"
require_relative "klin/application/lookup_workflow"
require_relative "klin/application/spa_workflow"
require_relative "klin/application/processing_workflow"

# XSD analysis (using lutaml-xsd library)
require_relative "klin/xsd_analyzer"

# XMI navigation
require_relative "klin/xmi_navigator"

# Mapping generation
require_relative "klin/mapping_generator"

module Lutaml
  module Klin
    class Error < StandardError; end
    class FatalError < Error; end
  end
end
