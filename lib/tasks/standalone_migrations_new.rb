# I really think we should deprecate this file, seems to me that is
# more explicit if the user require "standalone_migrations_new" and then
# call the load_tasks methods in his Rakefile. But this only a
# suggestion, and we can get rid of this comment if others on the
# project don't agree with that
#
# Ricardo Valeriano

require File.expand_path("../../standalone_migrations_new", __FILE__)
StandaloneMigrationsNew::Tasks.load_tasks
