
require('lore/exceptions/invalid_field')
require('lore/exceptions/unknown_type')
require('lore/adapters/postgres')

module Lore
module Validation

	class Type_Validator # :nodoc:

    @@type_validation_rules = {
      Lore::PG_BOOL               => Proc.new { |value, required| 
                                       (value == 't' || value == 'f' || value.empty? && !required)
                                     }, 
      Lore::PG_BYTEA              => Proc.new { |value, required| true }, 
      Lore::PG_INT                => Proc.new { |value, required|
                                       value && ((value.kind_of?(Integer) || value.to_i.to_s == value)) || 
                                       !required && (value.empty?)
                                     }, 
      Lore::PG_FLOAT              => Proc.new { |value, required|
                                       value && ((value.kind_of?(Integer) || value.kind_of?(Float) || value.to_f.to_s == value)) || 
                                       !required && (value.empty?)
                                     }, 
      Lore::PG_SMALLINT           => Proc.new { |value, required|
                                       value && ((value.kind_of?(Integer) || value.to_i.to_s == value) && 
                                        (value.to_i < 1024 && value.to_i > -1024)) || 
                                       !required && (value.empty?)
                                     }, 
      Lore::PG_DECIMAL            => Proc.new { |value, required| 
                                       value && (value.kind_of?(Integer) || value.to_f.to_s == value) ||
                                       !required && (value.empty?)
                                     }, 
      Lore::PG_TEXT               => Proc.new { |value, required| !required || !value.empty? }, 
      Lore::PG_VARCHAR            => Proc.new { |value, required| !required || !value.empty? }, 
      Lore::PG_CHARACTER          => Proc.new { |value, required| !required || !value.empty? }, 
      Lore::PG_TIME               => Proc.new { |value, required| !required || !value.empty? },  # TODO
      Lore::PG_DATE               => Proc.new { |value, required| !required || !value.empty? },  # TODO
      Lore::PG_TIMESTAMP          => Proc.new { |value, required| !required || !value.empty? },  # TODO
      Lore::PG_VCHAR_LIST         => Proc.new { |value, required| !required || !value.empty? },  # TODO
      Lore::PG_TIMESTAMP_TIMEZONE => Proc.new { |value, required| !required || !value.empty? }   # TODO
    }

		def typecheck(code, value, is_required)
      validation = @@type_validation_rules[code]
      return validation.call(value, is_required) if validation
			raise Lore::Exceptions::Unknown_Type.new(code, value)
		end

	end

end # module
end # module
