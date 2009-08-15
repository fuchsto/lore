
require('lore/cache/bits')

module Lore
module Cache

  class Cache_Read_Exception < ::Exception

    def initialize(klass_name, controller, mode, keys)

      @message = 'PStore file does not exist: [' << Lore::Cache.store_name(klass_name, controller, mode, keys) << ']'
      
    end # def

  end # class
  
  class Cache_Write_Exception < ::Exception

    def initialize(klass_name, controller, mode, keys)

      @message  = 'Error when trying to cache [' << Lore::Cache.store_name(klass_name, controller, mode, keys) << ']'
      @message += '(is caching enabled for this controller?)'
      
    end # def

  end # class


end # module
end # module
