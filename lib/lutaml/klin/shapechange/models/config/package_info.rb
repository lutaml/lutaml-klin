# frozen_string_literal: true

require "lutaml/model"

module Lutaml
  module Klin
    module Shapechange
      class PackageInfo < Lutaml::Model::Serializable
        attribute :package_name, :string
        attribute :ns, :string
        attribute :nsabr, :string
        attribute :xsd_document, :string
        attribute :version, :string

        xml do
          root "PackageInfo"
          map_attribute "packageName", to: :package_name
          map_attribute "ns", to: :ns
          map_attribute "nsabr", to: :nsabr
          map_attribute "xsdDocument", to: :xsd_document
          map_attribute "version", to: :version
        end

        # Strip leading/trailing spaces from string attributes
        def package_name=(value)
          @package_name = value&.strip
        end

        def ns=(value)
          @ns = value&.strip
        end

        def nsabr=(value)
          @nsabr = value&.strip
        end

        def xsd_document=(value)
          @xsd_document = value&.strip
        end

        def version=(value)
          @version = value&.strip
        end
      end
    end
  end
end
