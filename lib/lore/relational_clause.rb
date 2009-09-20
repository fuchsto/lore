
module Lore

  # Usage: 
  #
  #   r1 = Relational_Clause.new('first_field')
  #   r2 = Relational_Clause.new('second_field')
  #
  #   r1 == 2
  #   --> [ 'first_field', :eq, 2 ]
  #
  #   r1 > Some_Model.attribute
  #   --> [ 'first_field', :gt, Some_Model.attribute ]
  #
  #   (r1 > 2) & (r2 < 5)
  #   --> [ [ 'first_field', :gt, 2 ], :and, [ 'second_field', :lt, 5 ] ]
  #
  class Relational_Clause
  
    attr_accessor :rel_exp

    @@inverse_op = { 
      :eq      => [ :neq,     '!='          ], 
      :new     => [ :eq,      '=='          ],
      :and     => [ :or,      'OR'          ],
      :or      => [ :and,     'AND'         ],
      :gt      => [ :lte,     '<='          ],
      :lt      => [ :gte,     '>='          ],
      :gte     => [ :lt,      '<'           ],
      :lte     => [ :gt,      '>'           ], 
      :like    => [ :unlike,  'not like'    ], 
      :unlike  => [ :like,    'like'        ], 
      :between => [ :outside, 'not between' ], 
      :outside => [ :between, 'between'     ]
    }

    def initialize(field_name=nil)
      @field_name = field_name
      @rel_exp    = [ field_name ]
    end

    def to_s
      @field_name.to_s
    end

    def inspect
      "Relational_Clause(#{@field_name}) exp: #{@rel_exp.inspect} "
    end

    def ==(value)
      @rel_exp[1] = :eq
      @rel_exp[2] = '=='
      @rel_exp[3] = value
      return self
    end

    def <=>(value)
      @rel_exp[1] = :neq
      @rel_exp[2] = '!='
      @rel_exp[3] = value
      return self
    end

    def >(value)
      @rel_exp[1] = :gt
      @rel_exp[2] = '>'
      @rel_exp[3] = value
      return self
    end

    def <(value)
      @rel_exp[1] = :lt
      @rel_exp[2] = '<'
      @rel_exp[3] = value
      return self
    end

    def >=(value)
      @rel_exp[1] = :gte
      @rel_exp[2] = '>='
      @rel_exp[3] = value
      return self
    end

    def <=(value)
      @rel_exp[1] = :lte
      @rel_exp[2] = '<='
      @rel_exp[3] = value
      return self
    end

    def like(value)
      @rel_exp[1] = :like
      @rel_exp[2] = 'like'
      @rel_exp[3] = value
      return self
    end

    def and(other)
      @rel_exp = [ @rel_exp, :and, 'AND', other.rel_exp.dup ]
      return self
    end
    alias & and

    def or(other)
      @rel_exp = [ @rel_exp, :or, 'OR', other.rel_exp.dup ]
      return self
    end
    alias | or

    def between(range_begin, range_end)
      @rel_exp[1] = :between
      @rel_exp[2] = 'between'
      @rel_exp[3] = [ range_begin, :between_and, 'AND', range_end ]
      return self
    end

    def outside(range_begin, range_end)
      @rel_exp[1] = :outside
      @rel_exp[2] = 'not between'
      @rel_exp[3] = [ range_begin, :outside_and, 'AND', range_end ]
      return self
    end

    def in(value_set)
      # TODO
      return self
    end

    def not_in(value_set)
      # TODO
      return self
    end

    def has_element(element)
      # TODO
      return self
    end

    def has_element_like(element)
      # TODO
      return self
    end

    def has_element_ilike(element)
      # TODO
      return self
    end

    def negate!(rel_exp=nil)
      rel_exp ||= @rel_exp
      inv_op  = @@inverse_op[rel_exp[1]]
      rel_exp[1], rel_exp[2] = inv_op if inv_op
      negate!(rel_exp[0]) if rel_exp[0].is_a?(Array)
      negate!(rel_exp[3]) if rel_exp[3].is_a?(Array)
    end

    def negate
      clone = Relational_Clause.new(@field_name)
      clone.rel_exp = @rel_exp.dup
      clone.negate!
      clone
    end

    # Could be delegated to adapter
    def to_sql(rel_exp=nil)
      rel_exp ||= @rel_exp
      sql = ''
      if rel_exp[0].is_a?(Array) then
        sql << "(#{to_sql(rel_exp[0])})"
      else
        sql << rel_exp[0].to_s
      end
      sql << " #{rel_exp[2]} "
      if rel_exp[3].is_a?(Array) then
        sql << "(#{to_sql(rel_exp[3])})"
      else
        sql << "'#{rel_exp[3]}'"
      end
    end

    r1 = Relational_Clause.new('first')
    r2 = Relational_Clause.new('second')
    r1 == 20
    p r1.to_sql
    ((r1 == 5 ) | (r1.outside(1,10)))
    p r1.to_sql
    p r1.negate.to_sql

  end

end # module
