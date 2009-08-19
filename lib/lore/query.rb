
module Lore

  # Proxy class for Select queries. 
  #
  #   Model.select { |x| ... }    --> Select.new(Model, clause_parser)
  #
  class Select_Query

    attr_reader :model, :clause_parser

    def initialize(model, what=nil, &block)
      @model         = model
      @strategy      = model.__select_strategy__
      @what          = what
      @clause_parser = yield(Clause_Parser.new(@model))
    end

    def to_sql
      @strategy.select_query(@what, @clause_parser)[:query]
    end
    alias sql to_sql

    def perform
      @strategy.select_cached(@what, @clause_parser)
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

    def +(other)
      @clause_parser.union(other)
      return self
    end

    # Any undefined method is interpreted as 
    # kicker call. 
    def method_missing(meth, *args)
      perform.__send__(meth, *args)
    end

  end

  class Delete_Query
  end

  class Update_Query
  end

  class Insert_Query
  end

end
