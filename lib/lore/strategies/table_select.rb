
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
    def self.build_joined_query(accessor, 
                                join_type='JOIN', 
                                query_string='', 
                                joined_tables=[])
    # {{{
      associations     = accessor.__associations__
      top_table        = accessor.table_name
      is_a_hierarchy   = associations.joins()
      own_primary_keys = associations.primary_keys()
      own_foreign_keys = associations.foreign_keys()
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
            query_string  << "\n #{join_type} #{foreign_table} ON ("
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
                                            join_type, 
                                            query_string, 
                                            joined_tables)
        end
      }
      return query_string
    end # }}}

    protected

    def build_select_query(value_keys)
    # {{{
      raise ::Exception.new("This method is deprecated. ")

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

    def select_query(what=nil, clause_parser=nil, &block)
    # {{{
      # Example: 
      # select(Car.name) -> SELECT max(id)
      if what.instance_of? Clause then
        what = what.to_s 
      end
      
      if(what.nil? || what == '*' || what == '') then
        query_as_part = '*'
      else 
        query_as_part = what.to_s      
      end

      if block_given? then
        yield_obj  = Clause_Parser.new(@accessor)
        clause_parser = yield *yield_obj
      end
      
      query_string = 'SELECT '
      
      query_parts = clause_parser.parts
      query_parts[:what] = query_as_part
      query_parts[:from] = "FROM #{@accessor.table_name}"
      # Add JOIN part for system defined type (user defined 
      # joins will be set in Clause_Parser object in later 
      # yield): 
      if @accessor.is_polymorphic? then
        query_parts[:all_joins] = self.class.build_polymorphic_joined_query(@accessor) << query_parts[:join]
      else
        query_parts[:all_joins] = self.class.build_joined_query(@accessor) << query_parts[:join]
      end
      query_string << [ :what, :from, :all_joins, :where, 
                        :group_by, :having, :filter, 
                        :order_by, :limit, :offset ].map { |part|
        query_parts[part]
      }.join(' ')

      # Attaching UNION selects: 
      if clause_parser.unions then
        clause_parser.unions.each { |select_query_obj|
          query_string << "\nUNION\n"
          union_sql = select_query_obj.sql
          query_string << union_sql
        }
      end

      return { :query => query_string, :joined_models => clause_parser.parts[:joined] }
    end # }}}
    
    def self.build_polymorphic_joined_query(accessor)
    # {{{
      # Generates full outer join on all concrete submodels of this 
      # (abstract) polymorphic model. 
      
      # Correct query for this is: 
      # select * from asset 
      # ----  BEGIN IMPLICIT JOINS
      # -- full outer join on concrete model's base table
      # full outer join document_asset on (asset.asset_id = document_asset.asset_id) 
      #   -- left join on concrete model's implicitly joined tables
      #   left join document_asset_info on (document_asset_info.document_asset_id = document_asset.id)
      # -- full outer join on next concrete base table
      # full outer join media_asset on (asset.asset_id = media_asset.asset_id) 
      #   -- left join on concrete model's implicitly joined tables
      #   left join media_asset_info on (media_asset_info.media_asset_id = media_asset.id)
      # ----  END IMPLICIT JOINS
      # ----  BEGIN EXPLICIT JOINS
      # join Asset_Comments using (asset_id)
      # ----  END EXPLICIT JOINS
      # where ...
      # order by model;
      concrete_models = accessor.__associations__.concrete_models
      own_table_name  = accessor.table_name
      implicit_joins  = build_joined_query(accessor) 
      own_pkeys       = accessor.__associations__.primary_keys[own_table_name]
      concrete_models.each { |concrete_model|
        join_constraints = []
        concrete_model.__associations__.foreign_keys[concrete_model.table_name][own_table_name].first.each_with_index { |fkey,index|
          join_constraints << "#{own_table_name}.#{own_pkeys[index]} = #{concrete_model.table_name}.#{fkey}"
        }
        implicit_joins << "\nFULL OUTER JOIN #{concrete_model.table_name} ON (#{join_constraints.join(' AND ')}) "
        # Attach the concrete model's own implicit joins (is_a and aggregates), 
        # but don't join polymorphic base table (own_table_name) again: 
        implicit_joins << build_joined_query(concrete_model, '  LEFT JOIN', '', [own_table_name]) 
      }
      implicit_joins
    end # }}}

    def select(what, &block)
    # {{{
      query_string = select_query(what, nil, &block)
      return perform_select(query_string[:query])
    end # }}}

    def select_cached(what, clause_parser=nil, &block)
    # {{{
      joined_models = []
      query_string  = nil
      query         = nil
      if clause_parser.nil? && block_given? then
        query         = select_query(what, &block)
        query_string  = query[:query]
        joined_models = query[:joined_models]
      elsif !block_given? && clause_parser then
        query         = select_query(what, clause_parser)
        query_string  = query[:query]
        joined_models = query[:joined_models]
      else
        query_string  = what.to_s
      end
      what = false if what.empty?

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
          Lore.logger.debug { "Model #{@accessor.to_s} polymorphic? #{@accessor.is_polymorphic?}" }
          if !what && @accessor.is_polymorphic? then
            result.map! { |row|
              Lore.logger.debug { "Polymorphic select returned: #{row.inspect}" }
              tmp = @accessor.new(row, joined_models)
              concrete_model = tmp.get_concrete_model
              # TODO: filter row array fields for this accessor
              concrete_model.new(row, joined_models)
            }
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
