
require('lore/exception/invalid_parameter')
require('lore/exception/unknown_typecode')
require('lore/types')

module Lore
module Validation

	class Type_Validator # :nodoc:

		def typecheck(code, value, nil_allowed=true)

			case code

			# bool
			when Lore::PG_BOOL
				if value == 't' || value == 'f' || 
				   value == '' && nil_allowed || value.nil? && nil_allowed
				then true else false end
			# bytea
			when Lore::PG_BYTEA
        true
			# int
			when Lore::PG_INT 
				if value.kind_of?(Integer) or 
					value.to_i.to_s == value or 
					value.nil? && nil_allowed or
					value == '' && nil_allowed
				then true else false end
			# smallint
			when Lore::PG_SMALLINT 
				if ((value.kind_of?(Integer) or value.to_i.to_s == value or 
					value.nil? && nil_allowed || value == '' && nil_allowed)) and
					value.to_i < 1024 and value.to_i > -1024
				then true else false end
			# decimal
			when Lore::PG_DECIMAL
				if ((value.kind_of?(Integer) or value.to_f.to_s == value or 
					value.nil? && nil_allowed || value == '' && nil_allowed)) 
				then true else false end
			# text
			when Lore::PG_TEXT 
				if nil_allowed || !nil_allowed && !value.nil? && value != '' 
				then true else false end
			when Lore::PG_FLOAT
				if nil_allowed || !nil_allowed && !value.nil? && value != '' 
				then true else false end
			# varchar
			when Lore::PG_CHAR 
				if nil_allowed || !nil_allowed && !value.nil? && value != '' 
				then true else false end
			# varchar
			when Lore::PG_CHARACTER
				if nil_allowed || !nil_allowed && !value.nil? && value != '' 
				then true else false end
			# varchar
			when Lore::PG_VARCHAR 
				if nil_allowed || !nil_allowed && !value.nil? && value != '' 
				then true else false end
			# timestamp
			when Lore::PG_TIME
				# TODO
				if nil_allowed || !nil_allowed && !value.nil? && value != '' 
				then true else false end
			# timestamp with timezone
			when Lore::PG_TIMESTAMP
				# TODO
				if nil_allowed || !nil_allowed && !value.nil? && value != '' 
				then true else false end
			# timestamp with timezone
			when Lore::PG_TIMESTAMP_TIMEZONE 
				# TODO
				if nil_allowed || !nil_allowed && !value.nil? && value != '' 
				then true else false end
			# date
			when Lore::PG_DATE
				# TODO
				if nil_allowed || !nil_allowed && !value.nil? && value != '' 
				then true else false end

      # character varying[]
      when Lore::PG_VCHAR_LIST
        true
		
			else 
        raise ::Exception.new("Unknown type code ('#{code.inspect.to_s}') for value '#{value.inspect}'. See README on how to add new types. ")
			end
			
		end

	end

end # module
end # module
