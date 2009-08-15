
module Lore
module Exception

	class Ambiguous_Attribute < ::Exception

		def initialize(table_a, table_b, attribute)
			@message = 'Ambiguous attribute: '+attribute+ ' exists in '+table_a+' and '+table_b+'. '
		end

	end # class

end # module
end # module
