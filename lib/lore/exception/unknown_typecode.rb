
module Lore
module Exception
  
  class Unknown_Typecode < ::Exception
    
    attr_reader :code
    
    def initialize(_code)
      
      @code = _code
      @message = 'Unknown PGSQL type: ' + _code.to_s
      
    end
		
  end

end # module
end # module
