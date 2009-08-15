
require('logger')

module Lore
module Cache

  class Cached_Entities

    @@logger = Lore.logger
    @@mmap_cache = Hash.new
    @@file_index = Hash.new

  public

    def self.flush(type)
      index = type.table_name
      return if (!Lore.cache_entities() || @@file_index[index].nil?)
      @@file_index[index].each { |cache_file|
        @@logger.debug { 'Clearing cache file ' << cache_file }
        File.unlink(cache_file)
      }
      @@file_index.delete(type.table_name)
    end

    def self.[]=(query_string, result)
      if $cb__use_pstore_cache then
        create_pstore_cache(query_string, result) 
      else
        create_mmap_cache(query_string, result) 
      end
    end

    def self.create(accessor, query_string, result)
      if $cb__use_pstore_cache then
        file = create_pstore_cache(query_string, result) 
      else
        file = create_mmap_cache(query_string, result) 
      end
      @@file_index[accessor.table_name] = Array.new unless @@file_index[accessor.table_name]
      @@file_index[accessor.table_name] << file
    end

    def self.[](query_string)
      if $cb__use_pstore_cache then
        return read_pstore_cache(query_string)
      else 
        return read_mmap_cache(query_string)
      end
    end

    def self.include?(query_string)
      FileTest.exist?(storefile_of(query_string))
    end

  private

    def self.create_pstore_cache(query_string, result)
      storefile = storefile_of(query_string)
      store = create_store(storefile)
      store.transaction do
        store['dump'] = result
      end
      return storefile
    end

    def self.read_pstore_cache(query_string)
      store = create_store(storefile_of(query_string))
      result = Array.new
      store.transaction do
        result = store['dump']
      end
      return result
    end

    def self.create_mmap_cache(query_string, result)
      storefile = storefile_of(query_string)
      store = create_store(storefile)
      store.transaction do
        store['dump'] = result
      end
      @@mmap_cache[index_for(query_string)] = Mmap.new(storefile)
      return storefile
    end

    def self.read_mmap_cache(query_string)
      @@logger.debug { 'Loading from cache: ' << index_for(query_string) }
      store = @@mmap_cache[index_for(query_string)]
      @@logger.debug { 'STORE: ' << store.inspect }
      return [] unless store
      result = Marshal::load(store)
      return result['dump']
    end

    def self.delete_mmap_cache(index)
      @@mmap_cache[index].munmap
    end

  private

    def self.index_for(query)
      Digest::MD5.hexdigest(query)
    end

    def self.storefile_of(query)
      '/tmp/cb__cache__entities__' << Digest::MD5.hexdigest(query)
    end

    def self.create_store(storefile_name)
      store = PStore.new(storefile_name) unless storefile_name.nil?
      return store
    end

  end

end
end
