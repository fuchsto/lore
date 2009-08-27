
require('lore/exceptions/invalid_field')

module Lore
module Exceptions

  # A validation failure consists of one or more Invalid_Field 
  # instances for every model field for which invalid values have 
  # been passed, e.g. on Model.create or Model.update. 
  #
  # Usage: 
  #
  #   raise Validation_Failure.new(The_Model, { 
  #       # Generic error. Example:  :user_id => Lore.integer
  #         :table_foo  => Invalid_Field.new( :the_attribute => :error_type ) 
  #       # Constraint error. Example:  :email => :format 
  #         :table bar  => Unmet_Constraints.new( :the_attribute => :error_type )  
  #       # Type error. Example:  :user_id => Lore.integer or :user_id => :missing
  #         :table_batz => Invalid_Types.new( :the_attribute => :error_type ) 
  #   })
  #  
	class Validation_Failure < ::Exception
		
    # Instances of Exception::Invalid_Field
		attr_reader :invalid_fields
    # Model klass that failed validation
		attr_reader :invalid_klass
		
		def initialize(klass, invalid_params_hash)
      # Instances of Exception::Invalid_Field
			@invalid_fields = invalid_params_hash 
			@invalid_klass  = klass
      @message        = "#{self.class.to_s}: #{@invalid_fields.inspect}"
      log()
		end

    def log()
    # {{{ 
      Lore.logger.error { "====== VALIDATION FAILURE ===========" }
			Lore.logger.error { "Invalid field values for klass #{@invalid_klass}: " }
			Lore.logger.error { 'Invalid field values are: ' }
      @invalid_fields.each_pair { |table, ip|
        Lore.logger.error { " |- Table: #{table}: #{ip.inspect}" }
      }
			Lore.logger.error { 'Required attributes are: ' } 
      @invalid_klass.__attributes__.required.each_pair { |table, ip|
        Lore.logger.error { " |- Table: #{table}: #{ip.inspect}" } 
      }
		end # }}}

		def serialize() 
    # {{{
			serials = {}
			@invalid_fields.each_pair { |table, invalid_param|
				serials[table] = invalid_param.serialize
			}
			return serials
		end # def }}}
		
		def inspect()
			"Model(#{@invalid_klass}) => #{@invalid_fields.inspect} " << 
			"Required: #{@invalid_klass.__attributes__.required.inspect}"
		end
    alias explain serialize
		
	end


end # module
end # module

