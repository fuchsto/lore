
module Lore
module Exceptions

  # Usage: 
  #
  #   raise Lore::Exception::Invalid_Klass_Parameters.new(The_Model, { 
  #       # Generic error. Example:  :user_id => Lore.integer
  #           :table_foo  => Invalid_Parameters.new( :the_attribute => :error_type ) 
  #       # Constraint error. Example:  :email => :format 
  #           :table bar  => Unmet_Constraints.new( :the_attribute => :error_type )  
  #       # Type error. Example:  :user_id => Lore.integer or :user_id => :missing
  #           :table_batz => Invalid_Types.new( :the_attribute => :error_type ) 
  #   })
  #  
	class Invalid_Field_Value < ::Exception
		
		attr_reader :invalid_parameters
		attr_reader :invalid_klass
		
		def initialize(klass, invalid_params_hash)
      # Instances of Exception::Invalid_Parameters
			@invalid_parameters = invalid_params_hash 
			@invalid_klass 		  = klass
      @message            = "#{self.class.to_s}: #{@invalid_parameters.inspect}"
      log()
		end

		def log()
    # {{{ 
			Lore.logger.error { "Invalid field values for klass #{@invalid_klass}: " }
			Lore.logger.error { 'Invalid field values are: ' }
      @invalid_parameters.each_pair { |table, ip|
        Lore.logger.error { " |- Table: #{table}: #{ip.inspect}" }
      }
			Lore.logger.error { 'Required attributes are: ' } 
      @invalid_klass.__attributes__.required.each_pair { |table, ip|
        Lore.logger.error { " |- Table: #{table}: #{ip.join(', ')}" } 
      }
		end # }}}

		def serialize() # {{{
			serials = {}
			@invalid_parameters.each_pair { |table, invalid_param|
				serials[table] = invalid_param.serialize
			}
			return serials
		end # def }}}
		
		def inspect()
			"Model(#{@invalid_klass}) => #{@invalid_parameters.serialize} " << 
			"Required: #{@invalid_klass.__attributes__.required.inspect}"
		end
    alias explain serialize
		
	end


end # module
end # module

