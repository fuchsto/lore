
require('lore/validation/message')

module Lore
module Validation

  class Reason # :nodoc:

    @logger = Lore.logger

    attr_reader :options

    def message()
      @message
    end 
    
    def initialize(message, options) # {{{
      @message = message
      @options = options
    end # def }}}
    
    # Parameter validation failed: 
    def self.of_invalid_parameters(ikp) # {{{

      message = Lore::Validation::Error_Message.compose_error_message(ikp.serialize())
      @logger.debug('Reason message: '+message.inspect)
      return self.new(message, @options)
      
    end # def }}}

    # System exception:
    def self.of_user_runtime_error(excep) # {{{

      options = [:choice_critical, :choice_recommended] 
      message = Lang[excep.message]
      return self.new(message, options)
      
    end # def }}}
    
    # System exception:
    def self.of_exception(excep) # {{{

      options = [:choice_critical, :choice_recommended] 
      message = excep.message + ': ' + excep.backtrace.join('<br />')
      return self.new(message, options)
      
    end # def }}}
    
  end # class

end # module
end # module
