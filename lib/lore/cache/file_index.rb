
require 'lore/model'

Lore.disable_cache

module Lore
module Cache

  class File_Index < Lore::Model
    context :lore
    table :file_index, :public
    primary_key :file_index_id, :file_index_id_seq

    # Return array of cache file names depending 
    # from model
    def self.for(table_name)
      select { |i|
        i.where(i.model == table_name)
      }.collect { |index| 
        index.file
      }
    end

    def self.delete_entry(table_name)
      delete { |i| 
        i.where(i.model == table_name)
      }
    end

  end

end
end

Lore.enable_cache
