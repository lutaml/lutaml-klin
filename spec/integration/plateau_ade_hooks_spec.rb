# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/lutaml/klin/shapechange/rule_processors/plateau_ade_hooks_processor"
require_relative "../../lib/lutaml/klin/shapechange/rule_checker"
require_relative "../../lib/lutaml/klin/shapechange/rule_registry"
require_relative "../../lib/lutaml/klin/shapechange/standard_rules"
require_relative "../../lib/lutaml/klin/shapechange/base_encoding_rules"

RSpec.describe "PLATEAU ADE Hooks Generation" do
  let(:rule_registry) do
    registry = Lutaml::Klin::Shapechange::RuleRegistry.new
    Lutaml::Klin::Shapechange::BaseEncodingRules.load_into(registry)
    Lutaml::Klin::Shapechange.load_standard_rules(registry)
    registry
  end

  let(:rule_checker) do
    Lutaml::Klin::Shapechange::RuleChecker.new(rule_registry, "plateau")
  end

  let(:config) { double("config") }
  let(:processor) do
    Lutaml::Klin::Shapechange::RuleProcessors::PlateauAdeHooksProcessor.new(
      rule_checker,
      config
    )
  end

  describe "PLATEAU encoding rule" do
    it "is registered in the rule registry" do
      encoding_rule = rule_registry.encoding_rule("plateau")
      expect(encoding_rule).not_to be_nil
      expect(encoding_rule.name).to eq("plateau")
      expect(encoding_rule.extends).to eq("citygml")
    end

    it "includes the plateau-ade-hooks rule" do
      encoding_rule = rule_registry.encoding_rule("plateau")
      expect(encoding_rule.rules).to include("rule-xsd-cls-plateau-ade-hooks")
    end
  end

  describe "rule-xsd-cls-plateau-ade-hooks" do
    it "is registered as a rule definition" do
      rule_def = rule_registry.rule_definition("rule-xsd-cls-plateau-ade-hooks")
      expect(rule_def).not_to be_nil
      expect(rule_def.id).to eq("rule-xsd-cls-plateau-ade-hooks")
      expect(rule_def.scope).to eq("class")
      expect(rule_def.category).to eq("optional")
    end
  end

  describe "ADE mappings configuration" do
    it "loads 99 ADE hook mappings from YAML" do
      config_file = File.expand_path("../../../config/plateau_ade_mappings.yml", __dir__)
      expect(File.exist?(config_file)).to be true

      data = YAML.load_file(config_file)
      expect(data["ade_hooks"]).to be_an(Array)
      expect(data["ade_hooks"].size).to eq(99)
    end

    it "has valid mapping structure for each hook" do
      config_file = File.expand_path("../../../config/plateau_ade_mappings.yml", __dir__)
      data = YAML.load_file(config_file)

      data["ade_hooks"].each do |hook|
        expect(hook).to have_key("class")
        expect(hook).to have_key("element_name")
        expect(hook).to have_key("citygml_prefix")
        expect(hook).to have_key("citygml_base")
        expect(hook).to have_key("citygml_namespace")
      end
    end

    it "includes all CityGML module prefixes" do
      config_file = File.expand_path("../../../config/plateau_ade_mappings.yml", __dir__)
      data = YAML.load_file(config_file)

      prefixes = data["ade_hooks"].map { |h| h["citygml_prefix"] }.uniq.sort
      expected_prefixes = %w[bldg brid core dem frn grp luse tran tun veg wtr].sort

      expect(prefixes).to eq(expected_prefixes)
    end
  end

  describe "PlateauAdeHooksProcessor" do
    let(:xsd_doc) { double("xsd_document", prefix: "uro") }
    let(:context) { { xsd_document: xsd_doc, prefix: "uro" } }

    context "when processing DataQualityAttribute class" do
      let(:uml_class) do
        double("UML::Class",
               name: "DataQualityAttribute",
               is_a?: false)
      end

      it "generates ADE hook element for building extension" do
        expect(xsd_doc).to receive(:add_element).with(
          name: "bldgDataQualityAttribute",
          type: "uro:DataQualityAttributePropertyType",
          substitutionGroup: "bldg:_GenericApplicationPropertyOfAbstractBuilding"
        )

        expect(xsd_doc).to receive(:add_import).with(
          namespace: "http://www.opengis.net/citygml/building/2.0",
          location: "http://schemas.opengis.net/citygml/building/2.0/building.xsd"
        )

        processor.process(uml_class, context)
      end
    end

    context "when processing TrafficVolumeAttribute class" do
      let(:uml_class) do
        double("UML::Class",
               name: "TrafficVolumeAttribute",
               is_a?: false)
      end

      it "generates ADE hook element for road extension" do
        expect(xsd_doc).to receive(:add_element).with(
          name: "trafficVolumeAttribute",
          type: "uro:TrafficVolumeAttributePropertyType",
          substitutionGroup: "tran:_GenericApplicationPropertyOfRoad"
        )

        expect(xsd_doc).to receive(:add_import).with(
          namespace: "http://www.opengis.net/citygml/transportation/2.0",
          location: "http://schemas.opengis.net/citygml/transportation/2.0/transportation.xsd"
        )

        processor.process(uml_class, context)
      end
    end

    context "when processing class with type override" do
      let(:uml_class) do
        double("UML::Class",
               name: "FiscalYearOfPublication",
               is_a?: false)
      end

      it "uses the overridden type instead of PropertyType" do
        expect(xsd_doc).to receive(:add_element).with(
          name: "fiscalYearOfPublication",
          type: "xs:gYear",
          substitutionGroup: "grp:_GenericApplicationPropertyOfCityObjectGroup"
        )

        expect(xsd_doc).to receive(:add_import).with(
          namespace: "http://www.opengis.net/citygml/cityobjectgroup/2.0",
          location: "http://schemas.opengis.net/citygml/cityobjectgroup/2.0/cityObjectGroup.xsd"
        )

        processor.process(uml_class, context)
      end
    end

    context "when processing unmapped class" do
      let(:uml_class) do
        double("UML::Class",
               name: "UnmappedClass",
               is_a?: false)
      end

      it "does not generate any elements" do
        expect(xsd_doc).not_to receive(:add_element)
        expect(xsd_doc).not_to receive(:add_import)

        result = processor.process(uml_class, context)
        expect(result).to be false
      end
    end
  end

  describe "CityGML namespace imports" do
    it "maps all CityGML prefixes to correct schema locations" do
      expected_mappings = {
        "bldg" => "http://schemas.opengis.net/citygml/building/2.0/building.xsd",
        "brid" => "http://schemas.opengis.net/citygml/bridge/2.0/bridge.xsd",
        "tun" => "http://schemas.opengis.net/citygml/tunnel/2.0/tunnel.xsd",
        "luse" => "http://schemas.opengis.net/citygml/landuse/2.0/landUse.xsd",
        "wtr" => "http://schemas.opengis.net/citygml/waterbody/2.0/waterBody.xsd",
        "frn" => "http://schemas.opengis.net/citygml/cityfurniture/2.0/cityFurniture.xsd",
        "tran" => "http://schemas.opengis.net/citygml/transportation/2.0/transportation.xsd",
        "veg" => "http://schemas.opengis.net/citygml/vegetation/2.0/vegetation.xsd",
        "grp" => "http://schemas.opengis.net/citygml/cityobjectgroup/2.0/cityObjectGroup.xsd",
        "dem" => "http://schemas.opengis.net/citygml/relief/2.0/relief.xsd",
        "core" => "http://schemas.opengis.net/citygml/2.0/cityGMLBase.xsd"
      }

      expected_mappings.each do |prefix, location|
        expect(processor.send(:citygml_schema_location, prefix)).to eq(location)
      end
    end
  end

  describe "Integration: ADE hook count verification" do
    it "confirms all 99 VBA modifications are mapped" do
      config_file = File.expand_path("../../../config/plateau_ade_mappings.yml", __dir__)
      data = YAML.load_file(config_file)

      # Count by CityGML module
      building_hooks = data["ade_hooks"].select { |h| h["citygml_prefix"] == "bldg" }
      bridge_hooks = data["ade_hooks"].select { |h| h["citygml_prefix"] == "brid" }
      tunnel_hooks = data["ade_hooks"].select { |h| h["citygml_prefix"] == "tun" }
      landuse_hooks = data["ade_hooks"].select { |h| h["citygml_prefix"] == "luse" }
      waterbody_hooks = data["ade_hooks"].select { |h| h["citygml_prefix"] == "wtr" }
      furniture_hooks = data["ade_hooks"].select { |h| h["citygml_prefix"] == "frn" }
      transport_hooks = data["ade_hooks"].select { |h| h["citygml_prefix"] == "tran" }
      vegetation_hooks = data["ade_hooks"].select { |h| h["citygml_prefix"] == "veg" }
      group_hooks = data["ade_hooks"].select { |h| h["citygml_prefix"] == "grp" }
      dem_hooks = data["ade_hooks"].select { |h| h["citygml_prefix"] == "dem" }
      core_hooks = data["ade_hooks"].select { |h| h["citygml_prefix"] == "core" }

      # Verify counts match VBA analysis
      expect(building_hooks.size).to eq(25)  # 14 + 11 building elements
      expect(bridge_hooks.size).to eq(11)
      expect(tunnel_hooks.size).to eq(11)
      expect(landuse_hooks.size).to eq(8)
      expect(waterbody_hooks.size).to eq(8)
      expect(furniture_hooks.size).to eq(7)
      expect(transport_hooks.size).to eq(15)  # 7 + 3 + 5 transport elements
      expect(vegetation_hooks.size).to eq(6)
      expect(group_hooks.size).to eq(4)
      expect(dem_hooks.size).to eq(3)
      expect(core_hooks.size).to eq(1)

      total = building_hooks.size + bridge_hooks.size + tunnel_hooks.size +
              landuse_hooks.size + waterbody_hooks.size + furniture_hooks.size +
              transport_hooks.size + vegetation_hooks.size + group_hooks.size +
              dem_hooks.size + core_hooks.size

      expect(total).to eq(99)
    end
  end
end