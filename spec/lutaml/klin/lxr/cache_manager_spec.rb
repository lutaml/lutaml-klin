# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/lxr/cache_manager"
require "tempfile"
require "fileutils"

RSpec.describe Lutaml::Klin::Lxr::CacheManager do
  let(:temp_cache_dir) { Dir.mktmpdir("cache_manager_spec") }
  let(:cache_manager) { described_class.new(temp_cache_dir) }
  let(:temp_config) { Tempfile.new(["config", ".xml"]) }
  let(:temp_lxr) { Tempfile.new(["package", ".lxr"]) }

  after do
    temp_config.close
    temp_config.unlink
    temp_lxr.close
    temp_lxr.unlink
    FileUtils.rm_rf(temp_cache_dir) if Dir.exist?(temp_cache_dir)
  end

  describe "#initialize" do
    it "creates cache directory if it doesn't exist" do
      expect(Dir.exist?(temp_cache_dir)).to be true
    end

    it "uses default cache directory if none specified" do
      manager = described_class.new
      expect(manager.cache_dir).to eq(".lutaml-klin/cache")
    end
  end

  describe "#cached_lxr_path" do
    context "when config file doesn't exist" do
      it "raises InvalidInputError" do
        expect do
          cache_manager.cached_lxr_path("nonexistent.xml")
        end.to raise_error(Lutaml::Klin::Lxr::InvalidInputError, /not found/)
      end
    end

    context "when no cache exists" do
      it "returns nil" do
        result = cache_manager.cached_lxr_path(temp_config.path)
        expect(result).to be_nil
      end
    end

    context "when valid cache exists" do
      before do
        # Write some content to config and LXR
        temp_config.write("config content")
        temp_config.flush
        temp_lxr.write("lxr content")
        temp_lxr.flush

        # Cache the LXR
        cache_manager.cache_lxr(temp_lxr.path, temp_config.path)

        # Ensure cache file is newer than config
        sleep 0.1
      end

      it "returns cached LXR path" do
        result = cache_manager.cached_lxr_path(temp_config.path)
        expect(result).to be_a(String)
        expect(File.exist?(result)).to be true
      end
    end

    context "when cache is outdated" do
      before do
        # Write and cache
        temp_config.write("config content")
        temp_config.flush
        temp_lxr.write("lxr content")
        temp_lxr.flush
        cache_manager.cache_lxr(temp_lxr.path, temp_config.path)

        # Modify config to make it newer than cache
        sleep 0.1
        File.utime(Time.now, Time.now, temp_config.path)
      end

      it "returns nil and removes stale cache" do
        cached_path = cache_manager.send(:cache_file_path, temp_config.path)
        expect(File.exist?(cached_path)).to be true

        result = cache_manager.cached_lxr_path(temp_config.path)
        expect(result).to be_nil
        expect(File.exist?(cached_path)).to be false
      end
    end
  end

  describe "#cache_lxr" do
    before do
      temp_config.write("config content")
      temp_config.flush
      temp_lxr.write("lxr package content")
      temp_lxr.flush
    end

    it "copies LXR to cache directory" do
      result = cache_manager.cache_lxr(temp_lxr.path, temp_config.path)

      expect(File.exist?(result)).to be true
      expect(File.read(result)).to eq("lxr package content")
    end

    it "returns cached LXR path" do
      result = cache_manager.cache_lxr(temp_lxr.path, temp_config.path)
      expect(result).to include(temp_cache_dir)
      expect(result).to end_with(".lxr")
    end

    context "when source LXR doesn't exist" do
      it "raises PackageBuildError" do
        expect do
          cache_manager.cache_lxr("nonexistent.lxr", temp_config.path)
        end.to raise_error(Lutaml::Klin::Lxr::PackageBuildError, /not found/)
      end
    end

    context "when config doesn't exist" do
      it "raises InvalidInputError" do
        expect do
          cache_manager.cache_lxr(temp_lxr.path, "nonexistent.xml")
        end.to raise_error(Lutaml::Klin::Lxr::InvalidInputError, /not found/)
      end
    end
  end

  describe "#invalidate" do
    before do
      temp_config.write("config content")
      temp_config.flush
      temp_lxr.write("lxr content")
      temp_lxr.flush
    end

    context "when cache exists" do
      before do
        cache_manager.cache_lxr(temp_lxr.path, temp_config.path)
      end

      it "removes cached LXR and returns true" do
        cached_path = cache_manager.send(:cache_file_path, temp_config.path)
        expect(File.exist?(cached_path)).to be true

        result = cache_manager.invalidate(temp_config.path)
        expect(result).to be true
        expect(File.exist?(cached_path)).to be false
      end
    end

    context "when cache doesn't exist" do
      it "returns false" do
        result = cache_manager.invalidate(temp_config.path)
        expect(result).to be false
      end
    end
  end

  describe "#clean_old_caches" do
    let(:old_cache_file) { File.join(temp_cache_dir, "old_cache.lxr") }
    let(:recent_cache_file) { File.join(temp_cache_dir, "recent_cache.lxr") }

    before do
      # Create old cache file (35 days old)
      File.write(old_cache_file, "old content")
      old_time = Time.now - (35 * 24 * 60 * 60)
      File.utime(old_time, old_time, old_cache_file)

      # Create recent cache file
      File.write(recent_cache_file, "recent content")
    end

    it "removes caches older than specified days" do
      removed = cache_manager.clean_old_caches(30)

      expect(removed).to include(old_cache_file)
      expect(File.exist?(old_cache_file)).to be false
      expect(File.exist?(recent_cache_file)).to be true
    end

    it "returns array of removed file paths" do
      removed = cache_manager.clean_old_caches(30)
      expect(removed).to be_an(Array)
      expect(removed.size).to eq(1)
    end

    it "keeps files newer than max_age_days" do
      cache_manager.clean_old_caches(30)
      expect(File.exist?(recent_cache_file)).to be true
    end
  end

  describe "cache key generation" do
    it "generates unique keys for different config files" do
      config1 = Tempfile.new(["config1", ".xml"])
      config2 = Tempfile.new(["config2", ".xml"])

      begin
        config1.write("content 1")
        config1.flush
        config2.write("content 2")
        config2.flush

        key1 = cache_manager.send(:cache_key, config1.path)
        key2 = cache_manager.send(:cache_key, config2.path)

        expect(key1).not_to eq(key2)
      ensure
        config1.close
        config1.unlink
        config2.close
        config2.unlink
      end
    end

    it "includes config basename in key" do
      temp_config.write("content")
      temp_config.flush

      key = cache_manager.send(:cache_key, temp_config.path)
      basename = File.basename(temp_config.path, ".*")

      expect(key).to include(basename)
    end

    it "includes modification time in key" do
      temp_config.write("content")
      temp_config.flush

      key = cache_manager.send(:cache_key, temp_config.path)
      mtime = File.mtime(temp_config.path).to_i.to_s

      expect(key).to include(mtime)
    end
  end
end