require 'spec_helper'

module StandaloneMigrations
  describe Configurator, "which allows define custom dirs and files to work with your migrations" do

    context "default values when .standalone_configurations is missing" do

      let(:configurator) do
        Configurator.new
      end

      it "use config/database.yml" do
        configurator.config.should == 'config/database.yml'
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

    end

    context "using a .standalone_migrations file with configuration" do
    end

  end
end
