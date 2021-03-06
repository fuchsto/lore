
module Lore
module Exceptions

  class Invalid_Field < ::Exception
  
    attr_reader :invalid_params, :reason

    def initialize(invalid_params) 
      @invalid_params = invalid_params
      @reason = :invalid
    end
    alias fields invalid_params

    def serialize
      @invalid_params
    end
    def inspect
      @invalid_params.inspect
    end

  end

	class Invalid_Types < Invalid_Field
    def initialize(invalid_params)
      super(invalid_params)
      @reason = :type
    end
	end

	class Unmet_Constraints < Invalid_Field
    def initialize(invalid_params)
      super(invalid_params)
      @reason = :constraint
    end
	end
	
	
end # module
end # module
