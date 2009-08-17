
require('logger')
require('pstore')
require('digest/md5')
require('lore/exceptions/cache_exception')

module Lore
module Cache

  # When implementing your own entity cache, derive from and implement 
  # Abstract_Entity_Cache. 
  # Expected class methods are: 
  #  - flush
  #  - read(query_string)
  #  - create(model_klass, query_string, result)
  #  - include?(query_string)
  #  - delete(cache_index)
  #    cache_index being an MD5 sum of the query_string that 
  #    generated the cache entry. 
  #    In case you want cache indices other than MD5 sums, 
  #    define class method 
  #    index_for(query_string)
  #
  # Every model may use a different caching implementation. 
  # To enable a specific caching implenentation for a model, use:
  #
  #    class Your_Model < Lore::Model
  #      ...
  #      use_cache_impl The_Cache_Implementation_Klass
  #      ...
  #    end 
  #
  class Abstract_Entity_Cache

    # Delete all cache entries for this model
    def self.flush
      raise ::Exception.new('Not implemented')
    end

    # Read cached result for a specific query string. 
    # Returns array of model instances.  
    def self.read(accessor, query_string)
      raise ::Exception.new('Not implemented')
    end

    # Create cache entry for a specific query_string on a model. 
    # Expects result from given query string as it has to be 
    # returned when calling Cache_Implementation.read(query_string) 
    def self.create(accessor, query_object, result)
      raise ::Exception.new('Not implemented')
    end

    # Whether there is a cache entry for a query or not. 
    def self.include?(accessor, query_string)
      raise ::Exception.new('Not implemented')
    end

    # Delete a specific cache entry, parameter index being 
    # primary key (e.g. a hash value) in cache generated from 
    # a query. 
    def self.delete(index)
      raise ::Exception.new('Not implemented')
    end

  end

  module Cache_Helpers
    def index_for(query)
      Digest::MD5.hexdigest(query)
    end

    def storefile_of(model_name, query)
      "/tmp/lore_cache__#{model_name}_#{Digest::MD5.hexdigest(query)}"
    end

    def create_store(storefile_name)
      store = PStore.new(storefile_name) unless storefile_name.nil?
      return store
    end
  end

end
end
