module StandaloneMigrations
  @@callbacks ||= []

  def self.on_loaded(&block)
    @@callbacks << block
  end

  def self.run_on_load_callbacks
    @@callbacks.each do |callback|
      callback.call
    end
  end
end