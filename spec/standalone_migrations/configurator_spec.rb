require 'spec_helper'
require 'yaml'

module StandaloneMigrations
  describe Configurator, "which allows define custom dirs and files to work with your migrations" do

    describe "environment yaml configuration loading" do

      let(:env_hash) do
        {
          "development" => { "adapter" => "sqlite3", "database" => "db/development.sql" },
          "test" => { "adapter" => "sqlite3", "database" => "db/test.sql" },
          "production" => {"adapter" => "sqlite3", "database" => ":memory:" }
        }
      end

      let(:env_hash_other_db) do
        {
          "development" => { "adapter" => "mysql2", "database" => "database_name" },
          "test" => { "adapter" => "mysql2", "database" => "database_name" },
          "production" => {"adapter" => "mysql2", "database" => "database_name" }
        }
      end

      before(:all) do
        @original_dir = Dir.pwd
        Dir.chdir( File.expand_path("../../", __FILE__) )
        FileUtils.mkdir_p "tmp/db/default"
        Dir.chdir "tmp"
        File.open("db/default/config.yml", "w") do |f|
          f.write env_hash.to_yaml
        end
      end

      it "load the specific environment config" do
        config = Configurator.new.config_for(:development)
        config.should == env_hash["development"]
      end

      it "load the yaml with environment configurations" do
        config = Configurator.new.config_for(:development)
        config[:database].should == "db/development.sql"
      end

      it "allow access the original configuration hash (for all environments)" do
        Configurator.new.config_for_all.should == env_hash
      end

      context "customizing the environments configuration dynamically" do

        let(:configurator) { Configurator.new }
        let(:new_config) { { 'sbrobous' => 'test' } }

        before(:all) do
          Configurator.environments_config do |env|
            env.on "production" do
              new_config
            end
          end
        end

        it "allow changes on the configuration hashes" do
          configurator.config_for("production").should == new_config
        end

        it "return current configuration if block yielding returns nil" do
          Configurator.environments_config do |env|
            env.on "production" do
              nil
            end
          end
          configurator.config_for("production").should == new_config
        end

        it "pass the current configuration as block argument" do
          Configurator.environments_config do |env|
            env.on "production" do |current_config|
              current_config.should == new_config
            end
          end
        end

      end

      after(:all) do
        Dir.chdir @original_dir
      end

    end

    context "default values when .standalone_configurations is missing" do

      let(:configurator) do
        Configurator.new
      end

      it "use config/database.yml" do
        configurator.config.should == 'db/default/config.yml'
      end

      it "use db/migrate dir" do
        configurator.migrate_dir.should == 'db/default/migrate'
      end

      it "use db/seeds.rb" do
        configurator.seeds.should == "db/default/seeds.rb"
      end

      it "use db/schema.rb" do
        configurator.schema.should == "db/default/schema.rb"
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

      let(:yaml_hash_other_db) do
        {
          "db" => {
            "seeds"    => "db2/seeds.rb",
            "migrate"  => "db2/migrate",
            "schema"   => "db2/schema.rb"
          },
          "config" => {
            "database" => "config/config_other.yml"
          }
        }
      end

      let(:configurator) do
        file = ".standalone_migrations"
        File.open(file, "w") { |file| file.write(yaml_hash.to_yaml) }
        Configurator.new
      end

      context "with database environment variable passed" do

        before(:all) do
          ENV['DATABASE'] = "other_db"
        end

        let(:other_configurator) do
          file_other_db = ".other_db.standalone_migrations"
          File.open(file_other_db, "w") { |file| file.write(yaml_hash_other_db.to_yaml) }
          Configurator.new
        end

        it "look up named dot file" do
          other_configurator.config.should == yaml_hash_other_db['config']['database']
        end

        it "load config from named dot file" do
          other_configurator.migrate_dir.should == 'db2/migrate'
        end

        after(:all) do
          File.delete ".other_db.standalone_migrations"
          ENV['DATABASE'] = nil
        end

      end

      context "with some configurations missing" do

        let(:yaml_hash) do
          {
            "config" => {
              "database" => "file/config/database.yml"
            }
          }
        end

        it "use default values for the missing configurations" do
          configurator.migrate_dir.should == 'db/default/migrate'
        end

        it "use custom config from file" do
          configurator.config.should == yaml_hash["config"]["database"]
        end

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
