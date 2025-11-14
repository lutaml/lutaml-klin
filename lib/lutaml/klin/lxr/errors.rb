# frozen_string_literal: true

module Lutaml
  module Klin
    module Lxr
      # Base error for LXR creation operations
      class LxrCreationError < StandardError; end

      # Error raised when input parameters are invalid
      class InvalidInputError < LxrCreationError; end

      # Error raised when package building fails
      class PackageBuildError < LxrCreationError; end

      # Error raised when package validation fails
      class ValidationError < LxrCreationError; end

      # Error raised when configuration is invalid
      class ConfigurationError < LxrCreationError; end

      # Error raised when auto LXR creation fails
      class AutoLxrError < LxrCreationError; end

      # Error raised when cache operations fail
      class CacheError < AutoLxrError; end
    end
  end
end