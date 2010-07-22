
module Lore

  module Query

    attr_reader :model, :clause_parser

    def initialize(model, strategy, polymorphic=false, &block)
      @model         = model
      @strategy      = strategy
      @polymorphic   = polymorphic
      
      if block.arity == 1 then
        @clause_parser = yield(Clause_Parser.new(@model))
      elsif block.arity < 1 then
        @clause_parser = Clause_Parser.new(@model)
        @clause_parser = @clause_parser.instance_eval(&block)
      end
    end

    def to_sql
    end
    alias sql to_sql

    def perform
    end
    alias exec perform

    def inspect
      "Select_Query[model: #{@model}, clause: #{@clause_parser.inspect} ]"
    end

  end

  # Proxy class for Select queries. 
  #
  #   Model.select { |x| ... }    --> Select.new(Model, clause_parser)
  #
  class Select_Query < Array
    include Query

    def initialize(model, what=nil, polymorphic=false, &block)
      super(model, model.__select_strategy__, polymorphic, &block)
      @what = what
    end

    def to_sql
      @strategy.select_query(@what, @clause_parser, @polymorphic)[:query]
    end
    alias sql to_sql

    def perform
      @strategy.select_cached(@what, @clause_parser, @polymorphic)
    end
    alias to_a perform
    alias exec perform
    alias result perform

    def first
      perform.first
    end
    def last
      perform.last
    end
    def each(&block)
      perform.each(&block)
    end
    def each_with_index(&block)
      perform.each_with_index(&block)
    end

    def union(other)
      @clause_parser.union(other)
      return self
    end

    def +(other)
      perform + other.to_a
    end

    # Any undefined method is interpreted as 
    # kicker call. 
    def method_missing(meth, *args)
      perform.__send__(meth, *args)
    end
    
  end

  class Delete_Query
    include Query

    def initialize(model, polymorphic=false, &block)
      super(model, model.__delete_strategy__, polymorphic, &block)
    end
    def to_sql
      @strategy.query(@clause_parser, @polymorphic)[:query]
    end
    alias sql to_sql

    def perform
      @strategy.perform(@what, @clause_parser, @polymorphic)
    end
    alias to_a perform
    alias exec perform
  end

  class Update_Query
    include Query

    def initialize(model, polymorphic=false, &block)
      super(model, model.__update_strategy__, polymorphic, &block)
    end
    def to_sql
      @strategy.query(@what, @clause_parser, @polymorphic)[:query]
    end
    alias sql to_sql

    def perform
      @strategy.perform(@what, @clause_parser, @polymorphic)
    end
    alias to_a perform
    alias exec perform
  end

  class Insert_Query
    include Query

    def initialize(model, polymorphic=false, &block)
      super(model, model.__insert_strategy__, polymorphic, &block)
    end
    def to_sql
      @strategy.query(@what, @clause_parser, @polymorphic)[:query]
    end
    alias sql to_sql

    def perform
      @strategy.perform(@what, @clause_parser, @polymorphic)
    end
    alias to_a perform
    alias exec perform
  end

end
