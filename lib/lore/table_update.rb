
require('lore/connection')
require('lore/bits')

module Lore

  class Table_Update

    @logger = Logger.new(Lore.logfile)

    public

    def initialize(accessor)
      @accessor = accessor
    end

    private

    def self.atomic_update_query(table_name, 
                                 attributes, 
                                 primary_key_values, 
                                 value_keys, 
                                 explicit_fields)
    # {{{
      query_string = "\n"
      query_string += 'UPDATE '+table_name+' SET '

      set_string = String.new

      key_counter = 0
      attributes.each { |attribute_name|

        internal_attribute_name = attribute_name[0..24]
        value = value_keys[internal_attribute_name].to_s
        if value == '' then 
          value = value_keys[table_name+'.'+internal_attribute_name].to_s
        end

        # only include attribute to update query if 
        # this attribute is not marked for explicit updating or 
        # marked as explicit but non-empty: 
        if(
           !(explicit_fields && explicit_fields.include?(internal_attribute_name) && value.empty?) &&
           !(primary_key_values[attribute_name] && value.empty?)
          )
        
          if key_counter > 0
            set_string += ', '
          end # if
          set_string += attribute_name + '=\'' + value.to_s + '\' '
          
          key_counter = 1
          
        end # if
      }
      query_string += set_string

      query_string += 'WHERE '

      field_counter=0
      primary_key_values.each_pair { |field, value|
        query_string += field + '=\'' + value.to_s + '\' '
        if field_counter < primary_key_values.keys.length-1
          query_string += 'AND '
        end
        field_counter += 1
      }
      query_string += ';'
        
      query_string

    end # }}}

    def block_update(&block)
    # {{{
      query_string = "UPDATE #{@base_table} "

      if block_given? then
        yield_obj = Lore::Clause_Parser.new(@base_table)
        clause = yield *yield_obj
      end

      query_string += clause.set_part
      query_string += clause.where_part
      
      Lore::Context.enter(@accessor.get_context) if @accessor.get_context
      begin
        Lore::Connection.perform(query_string)
      ensure
        Lore::Context.leave if @accessor.get_context
      end

    end # }}}

    def self.update_query(table_name, 
                          is_a_hierarchy, 
                          
                          attributes,
                          primary_key_values,
                          value_keys,
                          explicit_fields,
                          
                          query_string='')
    # {{{
      is_a_hierarchy.each_pair { |table, base_tables| 
        
        # pass base tables first, recursively, as IS_A-based creation has
        # to be done bottom-up:
        query_string += update_query(table, 
                                     base_tables, 

                                     attributes, 
                                     primary_key_values, 
                                     value_keys,
                                     explicit_fields 
                                    ).to_s
      }
      # finally, add query string for this table: 
      query_string += atomic_update_query(table_name, 
                                          attributes[table_name], 
                                          primary_key_values[table_name], 
                                          value_keys[table_name], 
                                          explicit_fields[table_name]
                                         ).to_s
        
      query_string

    end # }}}

    protected

    def perform_update(accessor_instance)
    # {{{
      query_string = update_query(@accessor.get_table_name, 
                                  @accessor.get_is_a, 
                                  @accessor.get_attributes, 
                                  accessor_instance.get_primary_key_values, 
                                  accessor_instance.get_attribute_values, 
                                  @accessor.get_explicit)
      
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
