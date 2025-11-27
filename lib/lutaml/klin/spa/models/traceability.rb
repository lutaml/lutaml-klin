# frozen_string_literal: true

require "lutaml/model"
require_relative "lxr_package_info"
require_relative "lur_package_info"

module Lutaml
  module Klin
    module Spa
      module Models
        # Traceability information
        class Traceability < Lutaml::Model::Serializable
          attribute :resolution_strategies, :string, collection: true,
                                                     default: -> { [] }
          attribute :lxr_package_info, LxrPackageInfo
          attribute :lur_package_info, LurPackageInfo

          json do
            map "resolutionStrategies", to: :resolution_strategies
            map "lxrPackageInfo", to: :lxr_package_info
            map "lurPackageInfo", to: :lur_package_info
          end

          yaml do
            map "resolutionStrategies", to: :resolution_strategies
            map "lxrPackageInfo", to: :lxr_package_info
            map "lurPackageInfo", to: :lur_package_info
          end
        end
      end
    end
  end
end
