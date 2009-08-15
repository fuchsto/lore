
module Lore
module Exception

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
	class Invalid_Klass_Parameters < ::Exception
		
		attr_reader :invalid_parameters
		attr_reader :invalid_klass
		
		def initialize(klass, invalid_params_hash)
      # Instances of Exception::Invalid_Parameters
			@invalid_parameters = invalid_params_hash 
			@invalid_klass 		  = klass
      @message            = 'Invalid_Klass_Parameters: ' << @invalid_parameters.inspect
      log()
		end

		def log()
			Lore.logger.error('Invalid parameters for klass '+@invalid_klass.to_s+': ')
			Lore.logger.error('Invalid parameters: ')
      @invalid_parameters.each_pair { |table, ip|
        Lore.logger.error(' |- Table: ' << table + ': ' << ip.inspect)
      }
			Lore.logger.error('Explicit attributes: ')
      @invalid_klass.__attributes__.explicit.each_pair { |table, ip|
        Lore.logger.error(' |- Table: ' << table + ': ' << ip.join(', '))
      }
		end

		def serialize() # {{{

			serials = {}
			@invalid_parameters.each_pair { |table, invalid_param|
				serials[table] = invalid_param.serialize
			}
			return serials
			
		end # def }}}
		
		def inspect()
			'Model('+@invalid_klass.to_s+') => '+
			@invalid_parameters.serialize + 
			' Explicit: '+ 
			@invalid_klass.get_explicit_attributes.inspect
		end
    alias explain serialize
		
	end


end # module
end # module

