
require('lore/adapters/postgres/connection')

module Lore

  class Sequence
    
    def initialize(seq_name)
      @seq_name = seq_name
    end

    def next_value
      res = Connection.perform("SELECT nextval('#{@seq_name}')")
      STDERR.puts res.inspect
      res.get_row().first
    end

    def current_value
      res = Connection.perform("SELECT nextval('#{@seq_name}')")
      res.get_row().first
    end

  end

end
