
module Lore
module Exceptions
  
  class Unknown_Type < ::Exception
    
    attr_reader :code, :value
    
    def initialize(type_code, value)
      @code  = type_code
      @value = value
      super("Unknown database type: #{type_code.to_s} for value #{value.inspect}")
    end
		
  end

end # module
end # module
