require 'spec_helper'

module StandaloneMigrationsNew

  describe "Callbacks" do

    describe ".on_loaded" do

      it "responds to on_loaded" do
        expect(StandaloneMigrationsNew).to respond_to :on_loaded
      end

      it "responds to run_on_load_callbacks" do
        expect(StandaloneMigrationsNew).to respond_to :run_on_load_callbacks
      end

      it "can pass a block do on_loaded" do
        callback_was_called = false

        StandaloneMigrationsNew.on_loaded do
          callback_was_called = true
        end

        # invoke the callbacks
        StandaloneMigrationsNew.run_on_load_callbacks

        expect(callback_was_called).to be true
      end

      it "can pass multiple blocks to on_loaded" do
        callback_count = 0

        for i in 1..4
          StandaloneMigrationsNew.on_loaded do
            callback_count += 1
          end
        end

        StandaloneMigrationsNew.run_on_load_callbacks

        expect(callback_count).to eq(4)
      end

    end

  end

end
