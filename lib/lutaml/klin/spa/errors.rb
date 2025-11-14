# frozen_string_literal: true

module Lutaml
  module Klin
    module Spa
      # Base error for SPA module
      class SpaError < StandardError; end

      # Error when loading data fails
      class DataLoadError < SpaError; end

      # Error when merging data fails
      class MergeError < SpaError; end

      # Error when building indexes fails
      class IndexBuildError < SpaError; end
    end
  end
end