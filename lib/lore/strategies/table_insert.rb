
module Lore

  class Table_Insert
        
    public

    def initialize(accessor)
      @accessor        = accessor
      @aggregates      = accessor.__associations__.aggregate_klasses
      @is_a            = accessor.__associations__.base_klasses_tree
      @foreign_keys    = accessor.__associations__.foreign_keys
      @base_table      = accessor.table_name
      @fields          = accessor.__attributes__.fields
      @sequences       = accessor.__attributes__.sequences
      @sequence_values = {}
    end

    def perform_insert(value_keys)
    # {{{
      @aggregates.keys.each { |table|
        @is_a.delete(table)
      }
      
      Context.enter(@accessor.get_context) if @accessor.get_context
      Lore.logger.info { 'PERFORM INSERT on '+@accessor.to_s }

      @sequence_values = load_sequence_values(@sequences)
      
      # Parse sequence_values into value_keys where entries match the exact table: 
      # (thus, there is an explicit call like primary_key :this_field, :this_sequence)
      @sequence_values.each_pair { |table, fields|
        value_keys[table].update(@sequence_values[table])
      }
      # Parse sequence_values into value_keys where a table depends from a 
      # sequence field by IS_A
      value_keys 	 = update_sequence_values_deps(@accessor, 
                                                 @base_table, 
                                                 @is_a, 
                                                 value_keys)
      query_string = insert_query(@base_table, 
                                  @is_a, 
                                  value_keys)
      
      begin
        Lore::Connection.perform("BEGIN;\n#{query_string}\nCOMMIT;")
      rescue ::Exception => excep
        Lore::Connection.perform("ROLLBACK;")
        raise excep
      ensure
        Lore::Context.leave if @accessor.get_context
      end
      @accessor.flush_entity_cache()

      # value_keys now are extended by sequence values: 
      return value_keys
    end # }}}

    protected
    
    def load_sequence_values(sequences)
    # {{{
      sequence_values = Hash.new

      # We have to load sequences in correct order, so 
      # inherited sequence values work as expected: 
      sequence_load_order  = @accessor.__associations__.join_tables.flatten.reverse
      sequence_load_order << @accessor.table_name
      puts 'ORDER: ' << sequence_load_order.inspect
      sequence_load_order.each { |table_name|
        field = sequences[table_name]
        if field then
          field.each_pair { |field_name, sequence|

            if sequence.is_a?(Clause) then 
              # Sequence value is inherited, as caused by 
              #
              #   Model.is_a Parent_Model, :my_id
              #   Model.primary_key :my_id, Parent_Model.id
              #
              # Actual sequence value has to be present already, 
              # as it stems from a base model. 
              # This is why we ensure correct order when loading 
              # sequences. 
              seq_name_parts   = sequence.to_s.split('.')
              parent_seq_table = seq_name_parts[0..1].join('.')
              parent_seq_field = seq_name_parts[2].to_sym
              sequence_value   = sequence_values[parent_seq_table][parent_seq_field]
            else 
              pure_schema_name 	  = table_name.split('.')[0]
              pure_table_name 	  = table_name.split('.')[1]
              temp_sequence_name 	= "#{sequence}_temp"
              
              sequence_query_string = "SELECT nextval('#{pure_schema_name}.#{sequence}'::text) as #{temp_sequence_name}; "
              sequence_value_result = Lore::Connection.perform(sequence_query_string)
              sequence_value        = sequence_value_result.get_field_value(0, temp_sequence_name)
            end
            
            sequence_values[table_name] = Hash.new if sequence_values[table_name] == nil
            sequence_values[table_name][field_name.to_sym] = sequence_value
          }
        end
      }
      
      return sequence_values
    end # }}}
    
    def atomic_insert_query(table_name, value_keys)
    # {{{ 
      query_string = "\nINSERT INTO #{table_name} "
      
      value_string = String.new
      field_string = String.new
      key_counter = 0
      value_keys.each_pair { |field, value|
        
        field_string << "#{field}"
        value_string << "'#{value}'"
        if key_counter < value_keys.length-1
          field_string += ', '
          value_string += ', '
        end
        key_counter += 1
      }
      query_string += "(#{field_string}) \n VALUES (#{value_string}); "
      return query_string
    end # }}}
    
    def insert_query(table_name, 
                     is_a, 
                     value_keys, 
                     query_string='')
    # {{{
      is_a.each_pair { |table, base_tables| 
        
        # pass base tables first, recursively, as IS_A-based creation has
        # to be done bottom-up:
        query_string << insert_query(table, base_tables, value_keys).to_s
      }
      # finally, add query string for this table: 
      if(value_keys[table_name] != nil)
        query_string << atomic_insert_query(table_name, value_keys[table_name]).to_s
      else 
        Lore.logger.debug { "No initial attribute for IS_A related table #{table_name} given. " } 
      end
      query_string
    end # }}}
    
    def update_sequence_values_deps(accessor, table, is_a, value_keys)
    # {{{
      is_a.each_pair { |base_table, next_base_tables| 
        # extend each value_key with primary keys of its base table: 
        if @sequence_values.has_key?(base_table) then
          # For sequenced foreign keys, only one attribute is allowed! 
          own_fkey = @foreign_keys[table][base_table].first.first
          if own_fkey
          then
            foreign_pkey = @foreign_keys[table][base_table].at(1).first
            seq_val = @sequence_values[base_table][foreign_pkey]
            value_keys[table][own_fkey] = seq_val
          end
        end
        value_keys = update_sequence_values_deps(accessor, 
                                                 base_table, 
                                                 next_base_tables, 
                                                 value_keys)
      }
      return value_keys
    end # }}}
    
  end # class

end # module
