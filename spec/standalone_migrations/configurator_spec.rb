require 'spec_helper'
require 'yaml'

module StandaloneMigrations
  describe Configurator, "which allows define custom dirs and files to work with your migrations" do

    describe "environment yaml configuration loading" do


      let(:env_hash_other_db) do
        {
          "development" => { "adapter" => "mysql2", "database" => "database_name" },
          "test" => { "adapter" => "mysql2", "database" => "database_name" },
          "production" => {"adapter" => "mysql2", "database" => "database_name" }
        }
      end

      before(:all) do
        @env_hash = {
          "development" => { "adapter" => "sqlite3", "database" => "db/development.sql" },
          "test" => { "adapter" => "sqlite3", "database" => "db/test.sql" },
          "production" => {"adapter" => "sqlite3", "database" => ":memory:" }
        }
        @original_dir = Dir.pwd
        Dir.chdir( File.expand_path("../../", __FILE__) )
        FileUtils.mkdir_p "tmp/db"
        Dir.chdir "tmp"
        File.open("db/config.yml", "w") do |f|
          f.write @env_hash.to_yaml
        end
      end

      it "load the specific environment config" do
        config = Configurator.new.config_for(:development)
        expect(config).to eq(@env_hash["development"])
      end

      it "load the yaml with environment configurations" do
        config = Configurator.new.config_for(:development)
        expect(config["database"]).to eq("db/development.sql")
      end

      it "allow access the original configuration hash (for all environments)" do
        expect(Configurator.new.config_for_all).to eq(@env_hash)
      end

      context "customizing the environments configuration dynamically" do

        let(:configurator) { Configurator.new }

        before(:all) do
          @new_config = { 'sbrobous' => 'test' }
          Configurator.environments_config do |env|
            env.on "production" do
              @new_config
            end
          end
        end

        it "allow changes on the configuration hashes" do
          expect(configurator.config_for("production")).to eq(@new_config)
        end

        it "return current configuration if block yielding returns nil" do
          Configurator.environments_config do |env|
            env.on "production" do
              nil
            end
          end
          expect(configurator.config_for("production")).to eq(@new_config)
        end

        it "pass the current configuration as block argument" do
          Configurator.environments_config do |env|
            env.on "production" do |current_config|
              expect(current_config).to eq(@new_config)
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
        expect(configurator.config).to eq('db/config.yml')
      end

      it "use db/migrate dir" do
        expect(configurator.migrate_dir).to eq('db/migrate')
      end

      it "use db/seeds.rb" do
        expect(configurator.seeds).to eq("db/seeds.rb")
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
        expect(configurator.config).to eq(args[:config])
      end

      it "use custom migrate dir" do
        expect(configurator.migrate_dir).to eq(args[:migrate_dir])
      end

      it "use custom seeds" do
        expect(configurator.seeds).to eq(args[:seeds])
      end

      it "use custom schema" do
        expect(configurator.schema).to eq(args[:schema])
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
          expect(other_configurator.config).to eq(yaml_hash_other_db['config']['database'])
        end

        it "load config from named dot file" do
          expect(other_configurator.migrate_dir).to eq('db2/migrate')
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
            },
            "db" => {
              "seeds" => "file/db/seeds.rb"
            }
          }
        end

        it "use default values for the missing configurations" do
          expect(configurator.migrate_dir).to eq('db/migrate')
        end

        it "use custom config from file" do
          expect(configurator.config).to eq(yaml_hash["config"]["database"])
        end

        it "use custom config value from partial configuration" do
          expect(configurator.seeds).to eq(yaml_hash["db"]["seeds"])
        end

      end

      it "use custom config from file" do
        expect(configurator.config).to eq(yaml_hash["config"]["database"])
      end

      it "use custom migrate dir from file" do
        expect(configurator.migrate_dir).to eq(yaml_hash["db"]["migrate"])
      end

      it "use custom seeds from file" do
        expect(configurator.seeds).to eq(yaml_hash["db"]["seeds"])
      end

      it "use custom schema from file" do
        expect(configurator.schema).to eq(yaml_hash["db"]["schema"])
      end

      after(:all) do
        File.delete ".standalone_migrations"
        Dir.chdir @original_dir
      end

    end
  end
end
