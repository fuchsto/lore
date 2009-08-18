
require('lore/cache/cached_entities')
require('lore/clause')

module Lore

  class Table_Select 

    @@logger = Lore.logger
    
    public

    def initialize(accessor)
      @accessor = accessor
    end

    # Extracted, recursive method for building the JOIN-part of 
    # a SELECT query. 
    def self.build_joined_query(accessor=nil, query_string='', joined_tables=[])
    # {{{
      accessor       ||= @acessor
      associations     = accessor.__associations__
      top_table        = accessor.table_name
      is_a_hierarchy   = associations.joins()
      own_primary_keys = associations.primary_keys()
      own_foreign_keys = associations.foreign_keys()
   #  TODO: Check if dup is necessary
   #  joined_models = associations.joined_models.dup
      joined_models    = associations.joined_models

      # predefine
      own_p_keys       = Hash.new
      foreign_p_keys   = Hash.new
      on_string        = String.new
      field_counter    = 0

      is_a_hierarchy.each_pair { |foreign_table, foreign_base_tables|
        # Ensure no table is joined twice
        if !(joined_tables.include?(foreign_table)) then
          # [ [ a_id_f, a_id ], [ b_id_f, b_id ] ]
          mapping = own_foreign_keys[top_table][foreign_table]
          own_f_keys     = mapping.at(0)
          foreign_p_keys = mapping.at(1)

          if own_f_keys then
            joined_tables << foreign_table
            query_string  << "\n JOIN #{foreign_table} on ("
            on_string      = ''
            foreign_p_keys.uniq.each_with_index { |foreign_field, field_counter|
              # base.table.foreign_field = this.table.own_field
              on_string    << "#{foreign_table}.#{foreign_field} = #{top_table}.#{own_f_keys[field_counter]}"
              query_string << ", " if field_counter > 0
              query_string << on_string
            } 
            
            query_string << ')'
          end
            
          # sub-joins of joined table: 
          query_string = build_joined_query(joined_models[foreign_table].first, 
                                            query_string, 
                                            joined_tables)
        end
      }
      return query_string
    end # }}}

    protected

    def build_select_query(value_keys)
    # {{{
      query_string = "SELECT * FROM #{base_table} #{self.class.build_joined_query(@accessor)} WHERE "
      query_string << "\n WHERE "
    
      operator = '='
      field    = String.new
      value_keys[0].each_pair { |field, value|
      # Filtering values is not necessary when feeded with 
      # Lore::Attributes instance
        field = field.to_s
        if value.instance_of? Hash then
          value.each_pair { |attrib_name, attrib_value|
            query_string << "#{field}.#{attrib_name} #{operator} '#{attrib_value.to_s.lore_escape}' AND "
          }
        else
          query_string << "#{base_table}." if field.split('.')[2].nil?
          query_string << "#{field} #{operator} '#{value.to_s.lore_escape}' AND "
        end
      }
      # remove trailing AND: 
      query_string.chomp!(' AND ')
      
      return query_string
    end # }}}

    def plan_select_query(what, &block)
    # {{{
      auto_plan = Lore::Plan.new(clause, select_query(what, &block), @accessor)
    end # }}}
   
    public 

    def select_query(what=nil, clause = nil, &block)
    # {{{
      query_string = 'SELECT '
      
      # Example: 
      # select(Car.name) -> SELECT max(id)
      if what.instance_of? Lore::Clause then
        what = what.to_s 
      end
      
      if(what.nil? || what == '*' || what == '') then
        query_as_part = '*'
      else 
        query_as_part = what.to_s      
      end

      clause_string = ''
      if block_given? then
        yield_obj  = Lore::Clause_Parser.new(@accessor)
        clause  = yield *yield_obj
      end
      
      query_parts = clause.parts
      query_parts[:what]   = query_as_part
      query_parts[:from] = "FROM #{@accessor.table_name}"
      # Add JOIN part for system defined type (user defined 
      # joins will be set in Clause_Parser object in later 
      # yield): 
      query_parts[:join] = self.class.build_joined_query(@accessor) << " \n " << query_parts[:join]
      query_string << [ :what, :from, :join, :where, :group_by, :having, :filter, :order_by, :limit, :offset ].map { |part|
        query_parts[part]
      }.join(' ')

      # TODO: 
      #  Implement class Plan_Clause, offering exactly the same methods as Clause, 
      #  but generating a Plan instead the query. 
      #  Pass block& to Plan_Clause, too, only in case a plan is needed. 

      return { :query => query_string, :joined_models => clause.parts[:joined] }
      
    end # }}}

    def select(what, &block)
    # {{{
      query_string = select_query(what, &block)
      return perform_select(query_string[:query])
    end # }}}

    def select_cached(what, &block)
    # {{{
      joined_models = []
      query_string  = nil
      query         = nil
      if block_given? then
        query         = select_query(what, &block)
        query_string  = query[:query]
        joined_models = query[:joined_models]
      else 
        query_string  = what.to_s
      end

      result = Array.new
      if Lore.cache_enabled? && 
         @accessor.entity_cache && 
         @accessor.entity_cache.include?(@accessor, query) then
        result = @accessor.entity_cache.read(@accessor, query)
        result = [] if result.to_s == ''
      else
        Context.enter(@accessor.get_context) if @accessor.get_context
        begin 
          result = Lore::Connection.perform(query_string).get_rows()
          if false and @accessor.is_polymorphic? then

          else
            result.map! { |row|
              row = (@accessor.new(row, joined_models))
            }
          end
        rescue PGError => pge
          raise pge
        ensure
          Context.leave if @accessor.get_context
        end
        if Lore.cache_enabled? && @accessor.entity_cache then
          @accessor.entity_cache.create(@accessor, query, result)
        end
      end
      return result
    end # }}}

    def prepare(plan_name, args, &block)
    # {{{
      args_string = ''
      args.map { |a| a = Lore::TYPE_NAMES[a] } 
      if args.to_s != '' && args.length > 0 then args_string = "(#{args.join(',')})" end
      query_string = "PREPARE #{@accessor.table_name.gsub('.','_')}__#{plan_name.to_s}#{args_string} AS " << select_query(&block)[:query]
      begin
        Context.enter(@accessor.get_context) if @accessor.get_context
        result = Lore::Connection.perform(query_string)
      rescue ::Exception => excep
        @@logger.debug("Exception when preparing #{plan_name.to_s}: #{excep.message}")
      ensure
        Context.leave if @accessor.get_context
      end
    end # }}}

    def select_prepared(plan_name, *args)
    # {{{
      args_string = ''
      if args.to_s != '' && args.length > 0 then args_string = "(#{args.join(',')})" end
      query_string = "EXECUTE #{plan_name.to_s} #{args_string}; "
      return select_cached(query_string)
    end # }}}

    def deallocate(plan_name)
    # {{{
      begin
        query_string = "DEALLOCATE #{@accessor.table_name.gsub('.','_')}__#{plan_name.to_s}; "
        result = Lore::Connection.perform(query_string)
      rescue ::Exception => excep
      end
    end # }}}

    private

    def perform_select(query_string)
    # {{{
      Context.enter(@accessor.get_context) if @accessor.get_context
      begin 
        return Lore::Connection.perform(query_string)
      rescue PGError => pge
        raise pge
      ensure
        Context.leave if @accessor.get_context
      end
   end # }}}

  end # class

end # module
