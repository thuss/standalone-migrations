require 'spec_helper'

module StandaloneMigrations

  describe "Callbacks" do

    describe ".on_loaded" do

      it "responds to on_loaded" do
        StandaloneMigrations.should respond_to :on_loaded
      end

      it "responds to run_on_load_callbacks" do
        StandaloneMigrations.should respond_to :run_on_load_callbacks
      end

      it "can pass a block do on_loaded" do
        callback_was_called = false

        StandaloneMigrations.on_loaded do
          callback_was_called = true
        end

        # invoke the callbacks
        StandaloneMigrations.run_on_load_callbacks

        callback_was_called.should be_true
      end

      it "can pass multiple blocks to on_loaded" do
        callback_count = 0

        for i in 1..4
          StandaloneMigrations.on_loaded do
            callback_count += 1
          end
        end

        StandaloneMigrations.run_on_load_callbacks

        callback_count.should == 4
      end

    end

  end

end