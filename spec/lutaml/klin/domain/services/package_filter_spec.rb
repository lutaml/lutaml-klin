# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/domain/services/package_filter"

RSpec.describe Lutaml::Klin::Domain::Services::PackageFilter do
  describe "#initialize" do
    it "creates a filter with the given pattern" do
      filter = described_class.new("ModelRoot::i-UR::**")

      expect(filter.pattern_string).to eq("ModelRoot::i-UR::**")
      expect(filter.pattern_regex).to be_a(Regexp)
    end
  end

  describe "#matches?" do
    context "with ** wildcard (match all)" do
      let(:filter) { described_class.new("**") }

      it "matches any package path" do
        expect(filter.matches?("ModelRoot")).to be true
        expect(filter.matches?("ModelRoot::i-UR")).to be true
        expect(filter.matches?("ModelRoot::i-UR::urf")).to be true
        expect(filter.matches?("Any::Package::Path")).to be true
      end
    end

    context "with prefix and ** wildcard" do
      let(:filter) { described_class.new("ModelRoot::i-UR::**") }

      it "matches paths starting with the prefix" do
        expect(filter.matches?("ModelRoot::i-UR::urf")).to be true
        expect(filter.matches?("ModelRoot::i-UR::urf::Building")).to be true
        expect(filter.matches?("ModelRoot::i-UR::")).to be true
      end

      it "does not match paths without the prefix" do
        expect(filter.matches?("ModelRoot::Core")).to be false
        expect(filter.matches?("Other::i-UR::urf")).to be false
        expect(filter.matches?("ModelRoot")).to be false
      end
    end

    context "with suffix and ** wildcard" do
      let(:filter) { described_class.new("**::urf") }

      it "matches paths ending with the suffix" do
        expect(filter.matches?("ModelRoot::i-UR::urf")).to be true
        expect(filter.matches?("Other::Path::urf")).to be true
        expect(filter.matches?("::urf")).to be true
      end

      it "does not match paths without the suffix" do
        expect(filter.matches?("ModelRoot::i-UR::uro")).to be false
        expect(filter.matches?("ModelRoot::i-UR::urf::Building")).to be false
      end
    end

    context "with * wildcard (single segment)" do
      let(:filter) { described_class.new("ModelRoot::*::urf") }

      it "matches paths with any single segment in the middle" do
        expect(filter.matches?("ModelRoot::i-UR::urf")).to be true
        expect(filter.matches?("ModelRoot::Core::urf")).to be true
        expect(filter.matches?("ModelRoot::Extensions::urf")).to be true
      end

      it "does not match paths with multiple or no segments" do
        expect(filter.matches?("ModelRoot::urf")).to be false
        expect(filter.matches?("ModelRoot::i-UR::foo::urf")).to be false
      end
    end

    context "with exact match (no wildcards)" do
      let(:filter) { described_class.new("ModelRoot::i-UR::urf") }

      it "matches only the exact path" do
        expect(filter.matches?("ModelRoot::i-UR::urf")).to be true
      end

      it "does not match partial or extended paths" do
        expect(filter.matches?("ModelRoot::i-UR")).to be false
        expect(filter.matches?("ModelRoot::i-UR::urf::Building")).to be false
        expect(filter.matches?("Other::i-UR::urf")).to be false
      end
    end

    context "with nil or empty input" do
      let(:filter) { described_class.new("**") }

      it "returns false for nil" do
        expect(filter.matches?(nil)).to be false
      end

      it "returns false for empty string" do
        expect(filter.matches?("")).to be false
      end
    end

    context "with complex patterns" do
      it "handles multiple ** wildcards" do
        filter = described_class.new("**::Core::**")

        expect(filter.matches?("ModelRoot::Core::Building")).to be true
        expect(filter.matches?("Any::Path::Core::More::Paths")).to be true
      end

      it "handles mixed wildcards" do
        filter = described_class.new("ModelRoot::*::**")

        expect(filter.matches?("ModelRoot::i-UR::urf")).to be true
        expect(filter.matches?("ModelRoot::Core::Building::Type")).to be true
        expect(filter.matches?("ModelRoot::Extensions::")).to be true
      end
    end
  end

  describe "#filter_packages" do
    let(:package1) { double("Package", qualified_name: "ModelRoot::i-UR::urf") }
    let(:package2) { double("Package", qualified_name: "ModelRoot::i-UR::uro") }
    let(:package3) { double("Package", qualified_name: "ModelRoot::Core::Building") }
    let(:packages) { [package1, package2, package3] }

    it "filters packages based on pattern" do
      filter = described_class.new("ModelRoot::i-UR::**")
      result = filter.filter_packages(packages)

      expect(result).to contain_exactly(package1, package2)
    end

    it "returns empty array when no packages match" do
      filter = described_class.new("NonExistent::**")
      result = filter.filter_packages(packages)

      expect(result).to be_empty
    end

    it "returns all packages when using ** pattern" do
      filter = described_class.new("**")
      result = filter.filter_packages(packages)

      expect(result).to contain_exactly(package1, package2, package3)
    end

    it "supports custom path method" do
      custom_package = double("Package", full_path: "ModelRoot::i-UR::urf")
      filter = described_class.new("ModelRoot::i-UR::**")

      result = filter.filter_packages([custom_package], path_method: :full_path)

      expect(result).to contain_exactly(custom_package)
    end
  end

  describe "#to_s" do
    it "returns a human-readable description" do
      filter = described_class.new("ModelRoot::i-UR::**")

      expect(filter.to_s).to eq("PackageFilter[ModelRoot::i-UR::**]")
    end
  end

  describe "#inspect" do
    it "provides detailed debugging information" do
      filter = described_class.new("ModelRoot::**")
      inspect_str = filter.inspect

      expect(inspect_str).to include("PackageFilter")
      expect(inspect_str).to include("ModelRoot::**")
      expect(inspect_str).to include("regex=")
    end
  end
end
