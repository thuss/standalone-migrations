require 'spec_helper'
require 'yaml'

module StandaloneMigrations
  describe Configurator, "which allows define custom dirs and files to work with your migrations" do

    context "default values when .standalone_configurations is missing" do

      let(:configurator) do
        Configurator.new
      end

      it "use config/database.yml" do
        configurator.config.should == 'db/config.yml'
      end

      it "use db/migrate dir" do
        configurator.migrate_dir.should == 'db/migrate'
      end

      it "use db/seeds.rb" do
        configurator.seeds.should == "db/seeds.rb"
      end

      it "use db/schema.rb" do
        configurator.schema.should == "db/schema.rb"
      end

    end

    context "passing configurations as a parameter" do
      let(:args) do
        {
          :config       => "custom/config/database.yml",
          :migrate_dir  => "custom/db/migrate",
          :seeds        => "custom/db/seeds.rb",
          :schema       => "custom/db/schema.rb"
        }
      end

      let(:configurator) do
        Configurator.new args
      end

      it "use custom config" do
        configurator.config.should == args[:config]
      end

      it "use custom migrate dir" do
        configurator.migrate_dir.should == args[:migrate_dir]
      end

      it "use custom seeds" do
        configurator.seeds.should == args[:seeds]
      end

      it "use custom schema" do
        configurator.schema.should == args[:schema]
      end

    end

    context "using a .standalone_migrations file with configurations" do

      before(:all) do
        @original_dir = Dir.pwd
        Dir.chdir File.expand_path("../", __FILE__)
      end

      let(:yaml_hash) do
        {
          "db" => {
            "seeds"    => "file/db/seeds.rb",
            "migrate"  => "file/db/migrate",
            "schema"   => "file/db/schema.rb"
          },
          "config" => {
            "database" => "file/config/database.yml"
          }
        }
      end

      let(:configurator) do
        file = ".standalone_migrations"
        File.open(file, "w") { |file| file.write(yaml_hash.to_yaml) }

        Configurator.new
      end

      it "use custom config from file" do
        configurator.config.should == yaml_hash["config"]["database"]
      end

      it "use custom migrate dir from file" do
        configurator.migrate_dir.should == yaml_hash["db"]["migrate"]
      end

      it "use custom seeds from file" do
        configurator.seeds.should == yaml_hash["db"]["seeds"]
      end

      it "use custom schema from file" do
        configurator.schema.should == yaml_hash["db"]["schema"]
      end

      after(:all) do
        File.delete ".standalone_migrations"
        Dir.chdir @original_dir
      end

    end
  end
end
