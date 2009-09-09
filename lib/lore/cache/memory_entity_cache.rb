
require 'lore'
require 'lore/cache/abstract_entity_cache'
begin
  require 'mmap'
  require 'activesupport'
  require 'active_support/cache/memory_store'
rescue LoadError
  Lore.log { 'Mmap or ActiveSupport for Ruby could not be loaded. You won\'t be able to use Memory_Entity_Cache. ' }
  module ActiveSupport
    module Cache
      class MemoryStore
      end
    end
  end
end

module Lore
module Cache


  # Implementation of entity cache using MMapped PStor files. 
  # Derived from Abstract_Entity_Cache. 
  # Uses Lore::Cache::Cache_Helpers for generating PStor files. 
  class Memory_Entity_Cache < Abstract_Entity_Cache
  extend Cache_Helpers

    @@store = ActiveSupport::Cache::MemoryStore.new()


    def self.flush(accessor)
      index = accessor.table_name
      return unless Lore.cache_enabled? 
      Dir.glob("/tmp/lore_cache__#{index}*").each { |cache_file|
        Lore.logger.debug { 'Clearing cache file ' << cache_file.to_s.split('_').last }
        begin
          @@store.delete(cache_file.to_s.split('_').last)
        rescue ::Exception => excep
          # Another process already killed this file
        end
      }
    end

    def self.read(accessor, query_obj)
      Lore.logger.debug { 'Loading from cache: ' << index_for(query_obj[:query]) }
      store = @@store.read("#{accessor.table_name}--#{index_for(query_obj[:query])}")
      return [] unless store
      
      return store[:values]
    end

    def self.create(accessor, query_object, result)
      entry = query_object.update({ :values => result })
      @@store.write("#{accessor.table_name}--#{index_for(query_object[:query])}", entry) 
    end

    def self.include?(accessor, query_obj)
      hit = @@store.exist?("#{accessor.table_name}--#{index_for(query_obj[:query])}")
      Lore.logger.debug { 'Cache miss: ' << index_for(query_obj[:query]) } unless hit
      return hit
    end

    def self.delete(index)
      Lore.logger.debug { "Deleting index #{index}" }
      @@store.delete(index)
    end

  end

end
end


