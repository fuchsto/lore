
module Lore

  module Prepare

    # Defines prepared statements like 
    # The_Model.by_id(id), The_Model.latest_entries(id, amount) etc.
    def define_default_preps
      return
      unless @@prepared_statements[:default_preps] then
        pkey_attrib_name = table_name + '.' << @primary_keys[table_name].first.to_s
        prepare(:_by_id, Lore::Type.integer) { |e|
          e.where(self.__send__(pkey_attrib_name.to_s.split('.')[-1].intern) == Lore::Clause.new('$1'))
          e.limit(1)
        }
        prepare(:_latest, Lore::Type.integer) { |e|
          e.where(true)
          e.order_by(pkey_attrib_name, :desc)
          e.limit(Lore::Clause.new('$1'))
        }
        @@prepared_statements[:default_preps] = true
      end
    end

  end

  # Model extension for prepared statements
  module Prepare_Class_Methods

    @@prepared_statements = Hash.new

    def by_id(entity_id) 
      begin
        return _by_id(entity_id).first
      rescue ::Exception => excep
        if @@prepared_statements[:default_preps] then
          raise excep
        else
          raise ::Exception.new(excep.message + ' (call define_default_preps first?)')
        end
      end
    end

    # Prepares a query for execution. This offers four advantages: 
    # - The query doesn't have to be interpreted by the DB every time 
    # - The query call is available via direct method call. 
    # - DB validates against types, thus preventing SQL injection
    # - It doesn't Lore require to compose the query string again. This 
    #   effects the most significant performance gain (Up to 60% execution 
    #   time in some benchmarks)
    # Usage: 
    #
    #  Article.prepare(:by_name_and_date, Lore::Type::Integer, Lore::Type::Date) { |a,fields|
    #    a.where((Article.article_id == fields[0] & 
    #            (Article.date == fields[1]))
    #  }
    #  Article.by_name_and_date('Merry Christmas', '20081224')
    #
    # From the PostgreSQL 7.4 Manual: 
    #
    #  "In some situations, the query plan produced by for a prepared statement may be 
    #   inferior to the plan produced if the statement were submitted and executed normally. 
    #   This is because when the statement is planned and the planner attempts to determine 
    #   the optimal query plan, the actual values of any parameters specified in the 
    #   statement are unavailable. PostgreSQL collects statistics on the distribution of 
    #   data in the table, and can use constant values in a statement to make guesses about 
    #   the likely result of executing the statement. Since this data is unavailable when 
    #   planning prepared statements with parameters, the chosen plan may be suboptimal. To 
    #   examine the query plan PostgreSQL has chosen for a prepared statement, use 
    #   EXPLAIN EXECUTE. "
    #
    def prepare(plan_name, *args, &block)
    # {{{
    # log('PREPARE: TRYING CLASS METHOD ' << plan_name.to_s)
      if !@@prepared_statements[plan_name] then
        Table_Select.new(self).prepare(plan_name, args, &block)

    #   log('PREPARE: CREATE CLASS METHOD ' << plan_name.to_s)
        instance_eval("
        def #{plan_name.to_s}(*args) 
          execute_prepared(:#{plan_name}, args)
        end")
        @@prepared_statements[plan_name] = true
    #   log('PREPARE: CREATED CLASS METHOD ' << plan_name.to_s)
      end
    end # }}}

    def execute_prepared(plan_name, *args)
      plan_name = "#{table_name.gsub('.','_')}__#{plan_name.to_s}"
      Table_Select.new(self).select_prepared(plan_name, args)
    end



  end
  
end
