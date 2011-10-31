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

  end
end
