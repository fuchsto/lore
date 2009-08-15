
module Lore
module Validation

	class Message

		def [](serial_string) # {{{

			if $cb__message_strings[$lang].include?(serial_string) then
				return nil
			else 
				return $cb__message_strings[$lang][serial_string]
			end	

		end # def }}}

	end # class

	class Error_Message < Message

		@logger = Lore.logger

		def [](serial_string) # {{{
		
			if $cb__message_strings[$lang].include?(serial_string) then
				compose_error_message(serial_string)
			else 
				return $cb__error_strings[$lang][serial_string]
			end	
			
		end # def }}}

		def self.compose_error_message(serial_array) # {{{
			
			message = []
			serial_array.uniq!
			serial_array.each { |serial_code|
			# klass--name--given--typecode (from Invalid_Klass_Parameters) 
			# to [klass,name,given,typecode]
#				@logger.log('serial code: '+serial_code.to_s)
				invalid_parameter = serial_code.split('--')

				# try to resolve a human readable name for this parameter: 
				if !Lang[invalid_parameter[1]].nil? then inv_param_name = Lang[invalid_parameter[1]] 
				else inv_param_name = invalid_parameter[1] end
				
				if invalid_parameter[2] == '' then 
					message << Lang[:error__specify_value].gsub('{1}', inv_param_name)
				else
					message << Lang[:error__invalid_value].gsub('{1}', inv_param_name)
				end
			}
			return message
			
		end # def }}}

	end # class

end # module
end # module
