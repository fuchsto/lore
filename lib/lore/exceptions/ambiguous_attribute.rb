
module Lore
module Exceptions

	class Ambiguous_Attribute < ::Exception

		def initialize(table_a, table_b, attribute)
			@message = "Ambiguous attribute: #{attribute.inspect} exists in #{table_a} and #{table_b}. "
		end

	end # class

end # module
end # module
