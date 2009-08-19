
require('lore/model/table_accessor')
require('lore/query_shortcuts') # So far, a forward-declaration could do here as well

class String
  # Poor man's SQL injection prevention ... 
  def lore_escape
    self.gsub!("'","X")
    self.gsub!('"','X')
    self
  end
end

class Symbol
# {{{
  
  # Do not overload Symbol#==
  def eq(other)
    Lore::Clause.new(self.to_s)==(other)
  end
  alias is eq
  def >=(other)
    Lore::Clause.new(self.to_s)>=(other)
  end
  def <=(other)
    Lore::Clause.new(self.to_s)<=(other)
  end
  def >(other)
    Lore::Clause.new(self.to_s)>(other)
  end
  def <(other)
    Lore::Clause.new(self.to_s)<=(other)
  end
  def <=>(other)
    Lore::Clause.new(self.to_s)<=>(other)
  end
  def not(other)
    Lore::Clause.new(self.to_s)<=>(other)
  end
  def like(other)
    Lore::Clause.new(self.to_s).like(other)
  end
  def ilike(other)
    Lore::Clause.new(self.to_s).ilike(other)
  end
  def has_element(other)
    Lore::Clause.new(self.to_s).has_element(other)
  end
  def has_element_like(other)
    Lore::Clause.new(self.to_s).has_element_like(other)
  end
  def has_element_ilike(other)
    Lore::Clause.new(self.to_s).has_element_ilike(other)
  end
  def in(other)
    Lore::Clause.new(self.to_s).in(other)
  end
  def not_in(other)
    Lore::Clause.new(self.to_s).not_in(other)
  end
  def between(s,e)
    Lore::Clause.new(self.to_s).between(s,e)
  end

end # }}}

module Lore

  def self.parse_field_value(value)
      if value.instance_of? Clause then
        value = value.field_name
      else 
        value = value.to_s.lore_escape
        value = '\'' << value << '\''
      end
      value
  end

  # Usage: 
  # 
  #   Some_Klass.select { |k|
  #     k.join(Other_Klass).on(Some_Klass.foo == Other_Klass.bar) { |o|
  #       k.where(
  #         (o['foo'] == 1) & (o['bar'] <=> 2)
  #       )
  #       k.limit(10)
  #     }
  #
  class Join 
  # {{{

    def initialize(clause, base_klass, join_klass, type=:natural)
      @type = type
      @clause_parser = clause
      @base_klass = base_klass
      @join_klass = join_klass
      @string = ''
      # By joining with another klass, new attributes are added 
      # we have to include in the AS part of the query: 
      new_attributes = ''
      implicit_joins = ''
      @clause_parser.add_as(new_attributes)

      @implicit_joins = Table_Select.build_joined_query(join_klass)
    end

    def implicit_joins
      @implicit_joins
    end

    def plan_name
      @plan_name
    end

    def string
      @string
    end

    # Will transform into ON clause, as USING drops duplicate fields
    def using(key, &block)
      if @type == :natural then cmd = 'JOIN '
      elsif @type == :left then cmd = 'LEFT JOIN '
      elsif @type == :right then cmd = 'RIGHT JOIN '
      end
      key = key.to_s
      using_string =  "#{@base_klass.table_name}.#{key} = "
      using_string << "#{@join_klass.table_name}.#{key}"
      @string = "\n" << cmd << @join_klass.table_name << ' ON (' << using_string << ') '
      @clause_parser.append_join(self)
      yield @clause_parser # use extended clause parser for inner block argument
    end

    def on(clause, &block)
      if @type == :natural then cmd = 'JOIN '
      elsif @type == :left then cmd = 'LEFT JOIN '
      elsif @type == :right then cmd = 'RIGHT JOIN '
      end
      @string = cmd << @join_klass.table_name << ' ON (' << clause.to_sql << ') ' 
      @clause_parser.append_join(self)
      yield @clause_parser # use extended clause parser for inner block argument
    end

  end # class }}}
  
  # Clause objects are responsible for operands on Model attributes, 
  # as in WHERE parts of a query. 
  # Model klass methods named like one if its (possibly inherited) 
  # field names return a preconfigured Clause object on that field. 
  #
  # Example: 
  #
  #    (Car.num_seats > 100).to_sql  --> "public.vehicle.num_seats > '100'"
  #
  class Clause < String 
  # {{{

    attr_reader :field_name, :value_string, :left_side, :plan
    
    def initialize(field_name='', left_side='', value_string='', plan={})
      if field_name.instance_of?(TrueClass) then
        return (Clause.new('1') == '1')
      elsif field_name.instance_of?(FalseClass) then
        return (Clause.new('1') == '0')
      end
      @value_string  = value_string
      @left_side     = left_side
      @field_name    = field_name
    end

    def self.for(accessor)
      Clause_Parser.new(accessor)
    end

    # Check for Refined_Select needed for functionality of 
    # Refined_Select. Example: 
    # 
    #   User.all.with(User.user_id.in( Admin.all(:user_id) ))
    # 
    def not_in(nested_query_string)
      if(nested_query_string.instance_of? Refined_Select) then
        nested_query_string.to_inner_select
      else
        nested_query_string = nested_query_string.join(',') if nested_query_string.is_a?(Array)
        @value_string = @field_name << ' NOT IN (' << "\n" << nested_query_string.to_s << ') '
        Clause.new(@value_string, @left_side+@value_string)
      end
    end

    # Check for Refined_Select needed for functionality of 
    # Refined_Select. Example: 
    # 
    #   User.all.with(User.user_id.in( Admin.all(:user_id) ))
    # 
    def in(nested_query_string)
      if(nested_query_string.instance_of? Refined_Select) then
        nested_query_string = nested_query_string.to_select
      elsif nested_query_string.instance_of? Array then
        nested_query_string = nested_query_string.join(',')
        nested_query_string = 'NULL' if nested_query_string.length == 0
      elsif nested_query_string.instance_of? Range then
        return between(nested_query_string.first, nested_query_string.last)
      end
      @value_string = @field_name << ' IN (' << "\n" << nested_query_string.to_s << ') '
      Clause.new(@value_string, @left_side+@value_string)
    
    end

    def between(range_begin, range_end)
      @value_string = @field_name << " BETWEEN #{range_begin} AND #{range_end} "
      Clause.new(@value_string, @left_side+@value_string)
    end

    def +(value)
      if value.instance_of? String then 
        value = '\''+value.lore_escape+'\'::text'
      else 
        value = value.to_s.lore_escape
      end
      @value_string = @field_name.to_s + '+'+value
      return Clause.new(@value_string, @left_side.to_s+@value_string.to_s)
    end
    def -(value)
      if value.instance_of? String then 
        value = '\''+value.lore_escape+'\'::text'
      else 
        value = value.to_s.lore_escape
      end
      @value_string = @field_name + '-'+ value
      return Clause.new(@value_string, @left_side+@value_string)
    end

    def is_null()
      @value_string = @field_name + ' IS NULL'
      Clause.new(@value_string, @left_side+@value_string, '', @plan)
    end

    def is_not_null()
      @value_string = @field_name + ' IS NOT NULL'
      Clause.new(@value_string, @left_side+@value_string, '', @plan)
    end
	
    def <(value) 
      @value_string = @field_name + ' < ' << Lore.parse_field_value(value)
      Clause.new(@value_string, @left_side+@value_string, '', @plan)
    end
    def <=(value) 
      @value_string = @field_name + ' <= ' << Lore.parse_field_value(value)
      Clause.new(@value_string, @left_side+@value_string, '', @plan)
    end
    def >(value) 
      @value_string = @field_name + ' > ' << Lore.parse_field_value(value)
      Clause.new(@value_string, @left_side+@value_string, '', @plan)
    end
    def >=(value) 
      @value_string = @field_name + ' >= ' << Lore.parse_field_value(value)
      Clause.new(@value_string, @left_side+@value_string, '', @plan)
    end
    def like(value) 
      value = value.to_s.lore_escape
      @value_string = @field_name + ' LIKE ' << Lore.parse_field_value(value)
      Clause.new(@value_string, @left_side+@value_string, '', @plan)
    end
    def ilike(value) 
      value = value.to_s.lore_escape
      @value_string = @field_name + ' ILIKE ' << Lore.parse_field_value(value)
      Clause.new(@value_string, @left_side+@value_string, '', @plan)
    end
    def posreg_like(value) 
      value = value.to_s.lore_escape
      @value_string = @field_name + ' ~* ' << Lore.parse_field_value(value)
      Clause.new(@value_string, @left_side+@value_string, '', @plan)
    end
    def ==(value) 
      if value.instance_of? Clause then
        value = value.field_name
      else 
        value = value.to_s.lore_escape
        value = '\'' << value << '\''
      end
      if(value != :NULL)
        @value_string = @field_name << ' = ' << value
      else
        @value_string = @field_name << ' IS NULL' 
      end
      Clause.new(@value_string, @left_side+@value_string, '', @plan)
    end
    alias is ==

    def <=>(value) 
      if(value != :NULL)
        @value_string = @field_name << ' != ' << Lore.parse_field_value(value)
      else 
        @value_string = @field_name << ' NOT NULL '
      end
      Clause.new(@field_name, @left_side+@value_string, '', @plan)
    end
    alias is_not <=>

    def |(value) 
      return Clause.new('1') == '1' if value.instance_of?(TrueClass)
      return Clause.new('1') == '0' if value.instance_of?(FalseClass)
      @value_string = " OR #{value.left_side}"
      Clause.new(@value_string, "(#{@left_side+@value_string})", '', @plan)
    end
    alias or |
    def &(value) 
      return unless value
      return Clause.new('1') == '1' if value.instance_of?(TrueClass)
      return Clause.new('1') == '0' if value.instance_of?(FalseClass)
      if @left_side.gsub(' ','') != '' then
        @value_string = " AND #{value.left_side}"
      else 
        @value_string = value.left_side
      end
      Clause.new(@field_name, "(#{@left_side+@value_string})", '', @plan)
    end
    alias and &
    
    def has_element(element)
      element = element.to_s if element.kind_of? Clause
      element = '\''+element.lore_escape+'\'' if element.kind_of? String
      @value_string = element + ' = ANY ('  << @field_name+ ')'
      Clause.new(@value_string, @left_side+@value_string, '', @plan)
    end

    # This query requires a custom operator, defined by: 
    #
    #  create function rlike(text,text) returns bool as 'select $2 like $1' language sql strict immutable; 
    #  create operator ~~~ (procedure = rlike, leftarg = text, rightarg = text, commutator = ~~);
    #
    def has_element_like(element)
      element = element.to_s if element.kind_of? Clause
      element = '\''+element.lore_escape+'\'' if element.kind_of? String
      @value_string = element + ' ~~~ ANY ('  << @field_name+ ')'
      Clause.new(@value_string, @left_side+@value_string, '', @plan)
    end

    # This query requires a custom operator, defined by: 
    #
    #  create function irlike(text,text) returns bool as 'select $2 ilike $1' language sql strict immutable; 
    #  create operator ~~~~ (procedure = irlike, leftarg = text, rightarg = text, commutator = ~~);
    #
    def has_element_ilike(element)
      element = element.to_s if element.kind_of? Clause
      element = '\'' + element.lore_escape + '\'' if element.kind_of? String
      @value_string = element + ' ~~~~ ANY (' << @field_name+ ')'
      Clause.new(@value_string, @left_side+@value_string, '', @plan)
    end

    # Important to return @field_name here, as 
    # Table_Accessor.attribute should return 
    # schema.table_name.attribute. 
    # See Table_Accessor.load_attribute_fields
    def to_s
      @field_name.to_s
    end

    def tag 
      @field_name.gsub('.','--')
    end
    
    def inspect
      return 'Clause('+to_s+')'
    end

    def to_sql
      @left_side + @value_string
    end
    
  end # class }}}
  
  # parses / builds WHERE, GROUP BY, ORDER BY, LIMIT, ... 
  # part of the query: 
  class Clause_Parser 
  # {{{
    
    attr_reader :unions

    def initialize(base_accessor)

      @clause            = Hash.new
      @clause[:limit]    = ''
      @clause[:offset]   = ''
      @clause[:group_by] = ''
      @clause[:order_by] = ''
      @clause[:join]     = ''
      @clause[:as]       = ''
      @clause[:set]      = ''
      @clause[:filter]   = ''
      @clause[:where]    = 't'
      @clause[:joined]   = []
      @unions = false
      @base_accessor = base_accessor

    end # def

    def self.for(accessor)
      Clause_Parser.new(accessor)
    end

    def parts
      @clause
    end

    def where_part
      @clause[:where]
    end
    def as_part
      @clause[:as]
    end
    def join_part
      @clause[:join] 
    end
    def having_part
      @clause[:having] 
    end

    def filter_part
      return @clause[:order_by] << @clause[:limit] << @clause[:offset] << @clause[:group_by] << @clause[:having]
    end
    def set_part
      @clause[:set].chomp!(',')
      return ' SET ' << @clause[:set]
    end

    def plan_args
      @clause[:plan_args]
    end

    def plan_types
      @clause[:plan_types]
    end

    def plan_values
      @clause[:plan_values]
    end

    def plan_name
      @clause[:plan_name]
    end

    def set(attrib_value_hash)
    
      attrib_value_hash.each_pair { |attr_name, value|

        attr_name = attr_name.to_s unless attr_name.instance_of? String
        if value.instance_of? Clause then
          value = value.to_s.lore_escape
        else
          value = '\'' << value.to_s.lore_escape+'\'' 
        end
        # Postgres disallows full attribute names in UPDATE 
        # queries, so use field name only:
        Lore.log { 'Set Attrib: ' << attr_name.to_s }
        Lore.log { 'Set Value: ' << value.to_s }
        @clause[:set] << attr_name.to_s.split('.').at(-1).to_s + ' = ' << value.to_s + ','
      }
      return self

    end
      
    def to_sql
      clause = ''
      clause << @clause[:join].to_s 
      clause << @clause[:where].to_s 
      clause << @clause[:group_by].to_s 
      clause << @clause[:order_by].to_s 
      clause << @clause[:limit].to_s 
      return clause
    end # def

    def where(where_clause)
      if where_clause.instance_of? Clause then
        where_clause = where_clause.to_sql
      elsif where_clause.instance_of? TrueClass then
        where_clause = '\'t\''
      elsif where_clause.instance_of? FalseClass then
        where_clause = '\'f\''
      end
      @clause[:where] = "\nWHERE #{where_clause.to_s}"
      return self
    end # def

    # For usage in class Join only
    def add_join(join)
      @clause[:final_join] = join.implicit_joins
    end

    # TODO: Check if this is ever needed at all. Currently unused and untested. 
    def prepend_join(join)
      @clause[:join] = join.string << @clause[:join]
      @clause[:join] << join.implicit_joins

    end
    def append_join(join)
      @clause[:join] << join.string 
      @clause[:join] << join.implicit_joins
    end

    def add_as(string)
      @clause[:as] << string
    end

    def join(join_klass)
      # this Join instance also will update this Clause_Parser's 
      # as_part (so passing self is crucial): 
      @clause[:joined] << join_klass
      j = Join.new(self, @base_accessor, join_klass)
      return j
    end
    def left_join(join_klass)
      # this Join instance also will update this Clause_Parser's 
      # as_part (so passing self is crucial): 
      j = Join.new(self, @base_accessor, join_klass, :left)
      return j
    end
    def right_join(join_klass)
      # this Join instance also will update this Clause_Parser's 
      # as_part (so passing self is crucial): 
      j = Join.new(self, @base_accessor, join_klass, :right)
      return j
    end

    def union(select_query)
      @unions ||= []
      @unions << select_query
      return self
    end

    def limit(limit_val, offset_val=0)
      @clause[:limit] = ' LIMIT ' << limit_val.to_s
      @clause[:offset] = ' OFFSET ' << offset_val.to_s
      return self
    end # def

    def having(having_clause)
      @clause[:having] = ' HAVING ' << having_clause.to_sql
      return self
    end

    def group_by(*absolute_field_names)
      absolute_field_names.map! { |field|
        if field.instance_of? Clause then
          field = field.field_name.to_s
        else 
          field = field.to_s
        end
      }
      @clause[:group_by] = ' GROUP BY ' << absolute_field_names.join(',')
      return self
    end # def

    def order_by(order_field, dir=:asc)
      (dir == :desc)? dir_s = 'DESC' : dir_s = 'ASC'
      if @clause[:order_by]  == '' then
        @clause[:order_by] = ' ORDER BY ' 
      else
        @clause[:order_by] << ', '
      end
      @clause[:order_by] << order_field.to_s + ' ' << dir_s
      return self
    end # def

    def [](absolute_field_name)
      if absolute_field_name.instance_of? Clause then
        field_name = absolute_field_name.field_name.to_s
      else 
        field_name = absolute_field_name.to_s
      end
      
      return Clause.new(field_name)
    end # def

    def max(absolute_field_name)
      if absolute_field_name.instance_of? Clause then
        field_name = absolute_field_name.field_name.to_s
      else 
        field_name = absolute_field_name.to_s
      end
      return Clause.new("max(#{field_name})")
    end

    def method_missing(absolute_field_name)
      if absolute_field_name.instance_of? Clause then
        field_name = absolute_field_name.field_name.to_s
      else 
        field_name = absolute_field_name.to_s
      end
      
    # return Clause.new("#{@base_table}.#{field_name}")
      return Clause.new(field_name)
    end

    def id()
      return Clause.new("#{@base_accessor.table_name}.id")
    end

    def perform
    end

  # }}}
  end # class

end # module
