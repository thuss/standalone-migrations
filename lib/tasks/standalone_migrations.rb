# I really think we should deprecate this file, seems to me that is
# more explicit if the user require "standalone_migrations" and then
# call the load_tasks methods in his Rakefile. But this only a
# suggestion, and we can get rid of this comment if others on the
# project don't agree with that
#
# Ricardo Valeriano

require File.expand_path("../../standalone_migrations", __FILE__)
StandaloneMigrations::Tasks.load_tasks
