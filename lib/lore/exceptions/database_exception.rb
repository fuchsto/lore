
module Lore
module Exceptions

  class Database_Exception < ::Exception

    attr_reader :message

    def initialize(msg)
      @message = msg
    end

  end

end # module Exception
end # module Lore
