
require('lore/bits')

module Lore

  class Table_Delete

    @logger = Lore.logger

    public

    def initialize(accessor)
      @accessor = accessor
    end
    
    private
    
    def self.atomic_delete_query(table_name, primary_keys, value_keys)
    # {{{
      query_string = 'DELETE FROM '+table_name+' WHERE '
      
      field_counter=0
      primary_keys.each { |field|
        
        query_string << "#{field} ='" 
        value = value_keys[field].to_s
        if value == '' then 
          value = value_keys["#{table_name}.#{internal_attribute_name}"].to_s
        end

        query_string << "#{value}' "
        if field_counter < primary_keys.length-1
          query_string += 'AND '
        end
        field_counter += 1
      }
      query_string << '; '
        
      query_string
      
    end # }}}
    
    public 

    def block_delete(&block)
    # {{{
      query_string = "DELETE FROM #{@accessor.table_name} "
      
      if block_given? then
        yield_obj = Lore::Clause_Parser.new(@accessor.table_name)
        clause = yield *yield_obj
      end
      
      query_string += clause.where_part
      
      Lore::Context.enter(@accessor.get_context) if @accessor.get_context
      begin
        Lore::Connection.perform(query_string)
      ensure
        Lore::Context.leave if @accessor.get_context
      end
    end # }}}
    
    def self.delete_query(table_name, 
                          is_a_hierarchy, 
                          primary_keys, 
                          value_keys, 
                          query_string='')
    # {{{
      query_string += atomic_delete_query(table_name, 
                                          primary_keys[table_name], 
                                          value_keys
                                          ).to_s
      is_a_hierarchy.each_pair { |table, base_tables| 
        
        # pass base tables afterwards, recursively, as IS_A-based deletion has
        # to be done top-down (derived tabled first): 
        query_string = delete_query(table, 
                                    base_tables, 
                                   
                                    primary_keys, 
                                    value_keys, 
                                   
                                    query_string
                                   ).to_s
      }
      return query_string
    end # }}}
    
    public
    
    def perform_delete(value_keys)
    # {{{
      query_string = self.class.delete_query(@accessor.table_name, 
                                             @accessor.__associations__.base_klasses_tree, 
                                             @accessor.__associations__.primary_keys, 
                                             value_keys)
      
      Lore::Context.enter(@accessor.get_context) if @accessor.get_context
      begin
        Lore::Connection.perform("BEGIN;\n#{query_string}\nCOMMIT;")
      rescue ::Exception => excep
        Lore::Connection.perform("ROLLBACK;")
        raise excep
      ensure
        Lore::Context.leave if @accessor.get_context
      end
      @accessor.flush_entity_cache()
      
    end # }}}
    
  end # class

end # module
  
