
require('pstore')

require('lore/cache/bits')
require('lore/exception/cache_exception')

module Lore
module Cache

  module Cacheable

    @@cache_impl = false

    def entity_cache
      @@cache_impl 
    end

    def use_entity_cache(entity_cache_class)
      @@cache_impl = entity_cache_class 
    end

    def flush_entity_cache
      @@cache_impl.flush(self) if @@cache_impl
    end

    def create_entity_cache(query_string, result) 
      @@cache_impl.create(self, query_string, result) if @@cache_impl
    end

    def read_entity_cache(query_string)
      @@cache_impl.read(self, query_string) if @@cache_impl
    end

  end

end # module
end # module
