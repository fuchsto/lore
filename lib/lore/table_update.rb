
require('lore/connection')
require('lore/bits')

module Lore

  class Table_Update

    @logger = Logger.new(Lore.logfile)

    public

    def initialize(accessor)
      @accessor = accessor
      @base_table = accessor.table_name
    end

    private

    def atomic_update_query(accessor, 
                            primary_key_values, 
                            value_keys)
    # {{{

      return unless value_keys && value_keys.length > 0

      table      = accessor.table_name
    # attributes = accessor.get_fields_flat
      attributes = accessor.get_fields[table]
      required   = accessor.__attributes__.required[table]

      Lore.logger.debug { 'atomic update query' }
      Lore.logger.debug { '----- ' << table.to_s + ' ------' }
      Lore.logger.debug { 'Values: ' << value_keys.inspect }
      Lore.logger.debug { 'Fields: ' << attributes.inspect }
      Lore.logger.debug { 'Required: ' << required.inspect }

      query_string = "UPDATE #{table} SET "
      set_string   = String.new
      key_counter  = 0
      value_keys.each_pair { |attribute_name, value|

        internal_attribute_name = attribute_name.to_s[0..24].to_sym
        if value.empty? then 
          value = value_keys["#{table}.#{internal_attribute_name}"].to_s
        end

        # Disallow setting an empty value for required fields
        if !(required[attribute_name] && value.empty?) && !(value.nil?) then
          if key_counter > 0 then
            set_string += ', '
          end 
          set_string << "#{attribute_name} = '#{value}'"
          key_counter = 1
        end 
      }
      query_string << set_string

      query_string << ' WHERE '

      field_counter=0
      primary_key_values.each_pair { |field, value|
        query_string << "#{field} = '#{value}'"
        if field_counter < primary_key_values.keys.length-1
          query_string << ' AND '
        end
        field_counter += 1
      }
      query_string << "; "
        
      return query_string
    end # }}}

    public

    def block_update(&block)
    # {{{
      query_string = "UPDATE #{@base_table} "

      if block_given? then
        yield_obj = Lore::Clause_Parser.new(@accessor)
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

    def update_query(accessor, 
                     primary_key_values,
                     value_keys,
                     query_string='')
    # {{{
      Lore.logger.debug { 'Update query: ' }
      Lore.logger.debug { value_keys.inspect }
      Lore.logger.debug { primary_key_values.inspect }
      
      associations   = accessor.__associations__
      is_a_hierarchy = associations.base_klasses_tree()
      joined_models  = associations.base_klasses()
      is_a_hierarchy.each_pair { |table, base_tables| 
        
        # pass base tables first, recursively, as IS_A-based creation has
        # to be done bottom-up:
        Lore.logger.debug { 'For ' << table.to_s } 
        Lore.logger.debug { joined_models.inspect }
        query_string << update_query(joined_models[table].first, 
                                     primary_key_values, 
                                     value_keys
                                    ).to_s
      }
      # finally, add query string for this table: 
      table_name = accessor.table_name
      query_string << atomic_update_query(accessor, 
                                          primary_key_values[table_name], 
                                          value_keys[table_name]
                                         ).to_s
        
      query_string

    end # }}}

    public

    def perform_update(accessor_instance)
    # {{{
      query_string = update_query(@accessor, 
                                  accessor_instance.update_pkey_values, 
                               #  accessor_instance.get_attribute_value_map)
                                  accessor_instance.update_values)
      
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
