# frozen_string_literal: true

require_relative "lib/lutaml/klin/version"

Gem::Specification.new do |spec|
  spec.name = "lutaml-klin"
  spec.version = Lutaml::Klin::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "Bridge ShapeChange UML-to-XSD outputs with Lutaml Model"
  spec.description = <<~DESC
    Lutaml-Klin converts ShapeChange UML-to-XSD transformation outputs into
    Lutaml Model-compatible YAML mappings by parsing ShapeChange XML configs,
    reading UML models from XMI, analyzing XSD schemas, and generating
    machine-readable mapping files.
  DESC
  spec.homepage = "https://github.com/lutaml/lutaml-klin"
  spec.license = "BSD-2-Clause"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.adoc"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "lutaml-model", "~> 0.7"
  spec.add_dependency "lutaml"
  spec.add_dependency "lutaml-xsd"
  spec.add_dependency "moxml"
  spec.add_dependency "thor"
  spec.add_dependency "liquid"
  spec.add_dependency "sqlite3"
end
