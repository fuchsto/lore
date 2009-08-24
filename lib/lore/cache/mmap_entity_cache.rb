
require 'lore'
require 'lore/cache/abstract_entity_cache'
begin
  require 'mmap'
rescue LoadError
  Lore.log { 'Mmap for Ruby could not be found. You won\'t be able to use Mmap_Entity_Cache. ' }
end

module Lore
module Cache


  # Implementation of entity cache using MMapped PStor files. 
  # Derived from Abstract_Entity_Cache. 
  # Uses Lore::Cache::Cache_Helpers for generating PStor files. 
  class Mmap_Entity_Cache < Abstract_Entity_Cache
  extend Cache_Helpers

    def self.flush(accessor)
      index = accessor.table_name
      return unless Lore.cache_enabled? 
      Dir.glob("/tmp/lore_cache__#{index}*").each { |cache_file|
        Lore.logger.debug('Clearing cache file ' << cache_file)
        begin
          File.unlink(cache_file)
        rescue ::Exception => excep
          # Another process already killed this file
        end
      }
    end

    def self.read(accessor, query_obj)
      Lore.logger.debug { 'Loading from cache: ' << index_for(query_obj[:query]) }
      store = Mmap.new(storefile_of(accessor.table_name, query_obj[:query]))
      Lore.logger.debug { 'STORE: ' << store.inspect }
      return [] unless store
      result = Marshal::load(store)
      return result['dump']
    end

    def self.create(accessor, query_object, result)
      storefile = create_mmap(accessor, query_object, result)
    end
    def self.create_mmap(accessor, query_object, result)
      storefile = storefile_of(accessor.table_name, query_object[:query])
      store = create_store(storefile)
      store.transaction do
        store['dump'] = result
      end
      Lore.logger.debug('Creating cache entry for ' << storefile )
      Mmap.new(storefile)
      return storefile
    end

    def self.include?(accessor, query_obj)
      FileTest.exist?(storefile_of(accessor.table_name, query_obj[:query]))
    end

    def self.delete(index)
    end

  end

end
end


