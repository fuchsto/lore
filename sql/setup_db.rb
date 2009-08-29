
require 'lore'

module Lore

  Context.enter(ARGV[1])
  Connection.perform(setup_query)

end
