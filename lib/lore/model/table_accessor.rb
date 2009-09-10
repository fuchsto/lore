
require('logger')
require('rubygems')
require('lore')
require('lore/clause')
require('lore/model/aspect')
require('lore/model/associations')
require('lore/model/attribute_settings')
require('lore/model/filters')
require('lore/query')

require('lore/strategies/table_select')
require('lore/strategies/table_insert')
require('lore/strategies/table_update')
require('lore/strategies/table_delete')

require('lore/query_shortcuts')
require('lore/model/model_shortcuts')

require('lore/model/model_instance')
require('lore/model/polymorphic')
require('lore/model/prepare')
require('lore/model/mockable')
require('lore/cache/cacheable')

module Lore

class Table_Accessor 
  include Model_Instance
  extend Aspect
  extend Prepare
  extend Query_Shortcuts
  extend Model_Shortcuts
  extend Polymorphic_Class_Methods
  include Polymorphic_Instance_Methods
  extend Prepare_Class_Methods
  include Prepare
  extend Cache::Cacheable
  extend Mockable

  @@logger = Lore.logger

  def self.log(message, level=:debug)
    @@logger.debug(message)
  end
  def log(message, level=:debug)
    @@logger.debug(message)
  end

  # Set in load_attribute_fields()
  @__filters__      = false
  @__associations__ = false
  @__attributes__   = false
  
  def self.__filters__
    @__filters__
  end
  def self.__associations__
    @__associations__
  end
  def self.__attributes__
    @__attributes__
  end

  def self.__select_strategy__
    @select_strategy
  end
  def self.__insert_strategy__
    @insert_strategy
  end
  def self.__update_strategy__
    @update_strategy
  end
  def self.__delete_strategy__
    @delete_strategy
  end

  # Holds own table name, defaults to self.class if not given. 
  # If a schema has been set by 
  # table :table_name, :schema_name
  # table_name is schema_name.table_name
  @table_name       = String.new

  @labels           = Array.new

  public

  ##########################################################################
  # Constructor is usually wrapped by e.g. self.load or 
  # Model_Instancemarshal_load.
  # Constructor just accepts a value array, and returns a Table_Accessor 
  # instance holding it. 
  # Note that this method is operating on a Table_Accessor instance, not
  # on class Table_Accessor itself (see Model_Instance). 
  def initialize(values, joined_models=[], cache=nil) 
  # {{{
    # Note: 
    # 90% of additional time used on a query compared to 
    # plain, unprocessed SQL queries is consumed here - so 
    # be efficient! 
    
    @loaded_from_cache = (cache == :cached)
    @joined_models     = joined_models

    if @loaded_from_cache then
      @attribute_values_flat = values
    else
      @attribute_values_flat = {}
      field_index = 0
      models  = [ self.class ]
      models |= joined_models
      models.each { |model|
        tables = model.all_table_names
        fields = model.get_fields_flat
        # Increment over all fields, do not use each_with_index
        fields.each { |field|
          # First value set has precedence
          @attribute_values_flat[field] ||= values[field_index] 
          field_index += 1 
        }
      }
      # Applying filter to *all* attribute values, including derived attributes. 
      # This way, an output filter can be added in a derived type that does not 
      # exist in a base type. 

      return if self.class.output_filters_disabled?

      output_filters = self.class.__filters__.output_filters
      @attribute_values_flat.each_pair { |attribute, value|
        filter = output_filters[attribute]
        @attribute_values_flat[attribute] = filter.call(value) if filter
      }
    end
  end

  # To be used indirectly via Model.polymorphic_select
  # Parameter 'values' contains values for all fields returned from a 
  # polmymorphic select query. 
  def self.new_polymorphic(values, joined_models=[])
  # {{{
    # Parameter 'values' contains values for all fields returned from a 
    # polmymorphic select query. It thus contains (empty) fields that are 
    # not relevant for this model instance. 
    # Those have to be filtered out by resolving field indices and their 
    # offsets. 
    #
    # Model.new expects values in following order: 
    #
    #   [ own fields, base klass fields, aggregeate klass fields, custom join fields ]
    #
    # But polymorphic selects return: 
    #
    #   [ polymorphic base klass fields, own fields, other base klass fields ... ]
    #
    # So value array has to be transformed accordingly, which is rather 
    # complicated. 
    #
    fields               = get_fields_flat
    concrete_model_index = 0 
    concrete_model_name  = values[polymorphic_attribute_index]
    concrete_model       = eval(concrete_model_name)

    # We need to know where to inject values of the polymorphic 
    # base model: 
    concrete_base_joins   = concrete_model.__associations__.joins
    concrete_base_klasses = concrete_model.__associations__.base_klasses
    inject_index          = concrete_model.__attributes__.num_own_fields
    # Be sure to iterate just like in 
    # Table_Select.build_joined_query strategy!
    concrete_base_joins.each_pair { |table, foreign_base_tables|
      # Ignore base tables - their fields are added automatically 
      # via __attributes__.num_fields below. 
      base_model = concrete_base_klasses[table].first
      break if base_model == self # Offset ends with own fields
      inject_index += base_model.__attributes__.num_fields
    }

    # Amount of polymorphic fields defined in this model
    polymorphic_num_fields = @__attributes__.num_fields()
    # Field offset should point to index where concrete 
    # fields begin. 
    field_offset = 0 
    @__associations__.concrete_models.each { |cm|
      break if cm == concrete_model 
      concrete_model_index += 1
      field_offset += (cm.__attributes__.num_fields - polymorphic_num_fields)
    }

    field_offset_end = (field_offset + concrete_model.__attributes__.num_fields) 
    basic_values     = values[0...polymorphic_num_fields]
    concrete_values  = values[(polymorphic_num_fields + field_offset)...field_offset_end]
    
    # Basic values from polymorphic base model have to be injected 
    # into concrete values at inject_index. 
    instance_values  = concrete_values[0...inject_index]
    instance_values += basic_values # Inject happens here
    injected = concrete_values[inject_index..-1]
    instance_values += injected if injected

    concrete_model.new(instance_values, joined_models)
  end # }}}

  def self.disable_output_filters
    @output_filters_disabled = true
  end
  def self.enable_output_filters
    @output_filters_disabled = false
  end

  def self.output_filters_disabled? 
    @output_filters_disabled || false
  end

  def attribute_values_by_table
    return @attribute_values if @attribute_values

    # Note that attributes might have been shadowed 
    # in @attribute_values flat, as first attribute 
    # takes precedence in casse two tables with common 
    # field name have been joined. 
    values = @attribute_values_flat 

    @attribute_values = Hash.new
    field_index = 0

    models  = [ self.class ] 
    models |= @joined_models
    models.each { |model|
      tables = model.all_table_names
      fields = model.get_fields
      tables.each { |table|
        map = {}
        fields[table].each { |field_name|
          map[field_name] = values[field_index]
          field_index += 1
        }
        @attribute_values[table] = map
      }
    }

    # Applying filter to *all* attribute values, including derived attributes. 
    # This way, an output filter can be added in a derived type that does not 
    # exist in a base type. 
    output_filters = self.class.__filters__.output_filters

    @attribute_values.values.map { |v|
      v.each_pair { |attribute, value|
        filter = output_filters[attribute]
        value  = filter.call(value) if filter
        value
      }
    }

    @attribute_values_flat = {}
    @attribute_values.values.each { |map| @attribute_values_flat.update map }

    return @attribute_values
  end # }}}



  # Simulates inheritance: Delegate missing methods to parent Table_Accessor. 
  def self.method_missing(meth)
  # {{{ 
    if @is_a_klasses then
      @is_a_klasses.each_pair { |foreign_key, k|
        return (k.__send__(meth.to_s)) if k.respond_to? meth
      }
    end
    raise ::Exception.new('Undefined method '<< meth.to_s << ' for ' << self.to_s)
  end # }}}

  # Inspect method
  def self.inspect
  # {{{
    'Lore::Table_Accessor: ' << self.to_s
  end # }}}

  # Recursively gets primary keys from parent, if own
  # primary keys don't have been set, yet: 
  # Returns all derived primary keys WITHOUT OWN PKEYS. 
  def self.get_primary_keys 
  # {{{
    @__attributes__.primary_keys
  end # }}}

  # Return primary key names of own table only, 
  # i.e. skipping inherited ones. 
  def self.get_own_primary_keys
  # {{{
    if !@own_primary_keys then
      @own_primary_keys = @__attributes__.primary_keys[@table_name].uniq
    end
    @own_primary_keys
  end # }}}
  
  def self.key_array()
  # {{{
    # TODO: Use __attributes__ here
    keys = Array.new
    get_primary_keys.each_pair { |table, attribs|
      attribs.each { |attrib|
        keys.push attrib
      }
    }
    return keys
  end # }}}
  
  # Recursively gets sequences from parent, if own
  # sequences don't have been set, yet: 
  def self.get_sequences 
  # {{{
    
    if @sequences.nil? then
      if @is_a_klasses.nil? then
        return Hash.new
      else
        seq_map = Hash.new
        @is_a_klasses.each_pair { |foreign_key,k|
          seq_map[k.table_name] = k.get_sequences
        }
        return seq_map
      end
    else
      return @sequences
    end

  end # }}}
  
  def self.set_sequences(arg) # :nodoc:
  # {{{
    @sequences = arg
  end # }}}
  
  # Returns base table of this model as String. 
  def self.table_name 
    @table_name 
  end

  # Returns all (i.e. including joined) tables as 
  # Array of Strings, ordered by join order. 
  def self.all_table_names
  # {{{
    return @table_names if @table_names
    @table_names = [@table_name]
    @table_names += @__associations__.joins.keys_flat
    return @table_names
  end # }}}

  # Returns all attribute fields as Hash of Array of Strings, 
  # in the same order as defined in the table, mapped by 
  # table names. 
  # Example: (Article < Content)
  #   
  #   Article.get_fields 
  #   --> 
  #   { 
  #     'public.content' => [ :content_id, :title, :date ], 
  #     'public.article' => [ :author, :lead_in ]
  #   }
  #
  # Also see get_fields_flat. 
  #
  def self.get_fields
    @fields ||= @__attributes__.fields
    @fields
  end
  # Returns all attribute fields as Hash of Array of Strings, 
  # in the same order as defined in the table, mapped by 
  # table names. 
  # Example: (Article < Content)
  #   
  #   Article.get_fields_flat
  #   --> 
  #   [ :content_id, :title, :date, :author, :lead_in
  #
  # Also see example in documentation to get_fields. 
  #
  def self.get_fields_flat
    @fields_flat ||= @__attributes__.fields_flat
    @fields_flat
  end

  protected
  
  # If this model is not to be located in a projects default context, 
  # you can tell Cuba which context to use via
  #
  #   context :other_context_name
  #
  def self.context(context_name) 
  # {{{
    @context = context_name
  end 
  def self.get_context
    @context
  end
  # }}}
  
  # Define the base table of this model. 
  # Usage: 
  #
  #   class Content < Lore::Model
  #     table :content, :public   $ table name is 'public.content'
  #     ...
  #   end
  #
  def self.table(model_table, model_schema=nil)
  # {{{
    model_table = "#{model_schema}.#{model_table}" if model_schema
    @table_name = model_table
    init_model(); # Table name is all we need to bootstrap a model
  end # }}}

  # Usage: 
  #
  #   primary_key :some_field, :some_field_sequence_name
  #   primary_key :some_other_field, :some_other_field_sequence_name
  #
  def self.primary_key(*prim_key) 
  # {{{
    @__associations__.add_primary_key(prim_key.at(0), prim_key.at(1))
    @__attributes__.add_primary_key(prim_key.at(0), prim_key.at(1))
  end # }}}

  # Define this model as derived from another model class, 
  # which realized model inheritance. 
  # Note that ruby only allows only single inheritance itself, 
  # but is_a may be used for multiple inheritance, too. 
  # Usage: 
  #
  #   class Article < Content
  #     table :article, :public
  #     is_a Content, :content_id
  #     is_a Asset, :asset_id
  #   end
  #
  # Effects: 
  # Creating an Article record will also create referenced 
  # Content and Assed records. 
  # Selecting an Article entity will automatically join 
  # Content and Asset records. 
  # Filters and hooks from Content and Asset are inherited. 
  #
  #   Article.is_a?(Content)   --> true
  #   Article.is_a?(Asset)     --> true(!)
  #
  def self.is_a(*args)
  # {{{
    parent = args.at(0)
    
    @__filters__.inherit(parent)
    @__attributes__.add_base_model(parent)
    @__associations__.add_base_model(parent, args[1..-1])

    define_entity_access_methods(parent, args[1..-1])
  end # }}}

  # Usage in derived classes: 
  #   aggregates Other::Module::Other_Klass
  #   aggregates Another::Module::Another_Klass
  # 
  # Effects: 
  # Performs eager join on given model on every select on this model. 
  # Unlike is_a, If foo.aggregates bar then creating/deleting a foo will not 
  # create/delete bar instance, but loading a foo will aggregate bar 
  # automatically, like is_a. 
  def self.aggregates(*args) 
  # {{{
    parent = args.at(0)
    
    @__filters__.inherit(parent)
    @__attributes__.add_aggregate_model(parent)
    @__associations__.add_aggregate_model(parent, args[1..-1])

    define_entity_access_methods(parent, args[1..-1])
  end # }}}


  class << self
    alias org_is_a? is_a?
    def is_a?(model)
      org_is_a?(model) || @__associations__ &&  @__associations__.has_joined_model?(model)
    end
  end
  
  # Usage: 
  #
  #   has_a Other_Model, :foreign_key_1 <, foreign_key_2, ... >
  #
  # note that foreign_keys are fields in _this_ table, 
  # not the foreign one. 
  #
  def self.has_a(*args)
  # {{{
    @__associations__.add_has_a(args.at(0), args[1..-1])
    define_entity_access_methods(args.at(0), args[1..-1])
  end # }}}

  # Usage: 
  #
  #   has_n Other_Model, :foreign_key_1 <, foreign_key_2, ... >
  #
  # note that foreign_keys are fields in _this_ table, 
  # not the foreign one. 
  #
  def self.has_n(other, *args)
  # {{{
    @__associations__.add_has_n(other, *args)
    define_entities_access_methods(args.at(0), args[1..-1])
   end # }}}

  # Usage: 
  #
  #   maps Model_A => [ :foreign_keys, ... ], Model_B => [ foreign_keys, ... ]
  #
  # note that foreign_keys are fields in _this_ table, 
  # not the foreign one. 
  #
  def self.maps(*accessors)
  # {{{
    @__associations__.add_mapping(*accessors)
  end # }}}
  
  def self.validates(attrib, constraints)
  # {{{
    @__attributes__.add_constraints(attrib, constraints)
  end # }}}

  def self.add_input_filter(attrib, &block) 
    @__filters__.add_input_filter(attrib, &block)
  end
  
  def self.add_output_filter(attrib, &block) 
    @__filters__.add_output_filter(attrib, &block)
  end

  # Demands a value to be set for create and update procedures. 
  def self.expects(attrib_name, klass=nil)
  # {{{
    @__attributes__.set_required(attrib_name)
  end # }}}

  def self.explicit(*args)
    Aurita.log { "Model.explicit is deprecated (called for #{self.to_s}" } 
  end

  def self.hide_attribute(*args)
    Aurita.log { "Model.hidden_attribute is deprecated (called for #{self.to_s}. 
                  Use Model.hidden instead" } 
  end

  # Define an attribute as hidden. 
  # Especially needed for form generation (hidden fields)
  def self.hides(attrib_name)
  # {{{
    @__attributes__.add_hidden(attrib_name)
  end 

  def self.get_hidden() 
    return @hidden_attributes if @hidden_attributes
    Hash.new
  end # }}}
  
  def self.belongs_to(*args)
  # {{{
    @__associations__.add_belongs_to(args.at(0), args[1..-1])
  end # }}}

  # Define attribute to use as label for instances of a Table_Accessor, 
  # e.g. for select boxes. 
  def self.use_label(*attribs)
  # {{{
    @labels = attribs.map { |e| 

      e = e.to_s # also removes Array wraps like [:attrib_name]

      if((e.kind_of? Clause) or (e.include?('.'))) then
        e = e.to_s 
      else
        e = @table_name + '.' << e.to_s
      end
    }
    @label = attribs[0]
  end
  # Returns full name of attribute set to use as label e.g. for 
  # select boxes. 
  def self.get_label
    @label
  end

  def self.get_labels
    @labels
  end

  # }}}
  
  public
  
  # Returns full attribute name of given attribute
  def self.[](attribute_name)
  # {{{
    return "#{@table_name}.#{attribute_name}"
  end # }}}


  def self.update(&block)
  # {{{
    query_string = @update_strategy.block_update(&block)
  end # def }}}
  
  def self.select(clause=nil, &block)
  # {{{
    if(!clause.nil? && !clause.to_s.include?('*,')) then
      query_string = @select_strategy.select_query(clause.to_s, &block)
      return Clause.new(query_string[:query])
    end
    return Select_Query.new(self, clause.to_s, &block)
  end # }}}

  def self.select_query(clause=nil, &block)
    query_string = @select_strategy.select_query(clause.to_s, &block)
  end

  def self.polymorphic_select(clause=nil, &block)
  # {{{
    if(!clause.nil? && !clause.to_s.include?('*,')) then
      query_string = @select_strategy.select_query(clause.to_s, nil, true, &block)
      return Clause.new(query_string[:query])
    end
    return Select_Query.new(self, clause.to_s, true, &block)
  end # }}}

  def self.polymorphic_select_query(clause=nil, &block)
    query_string = @select_strategy.select_query(clause.to_s, nil, true, &block)
  end

  # Same as select, but returns scalar value. 
  def self.select_value(what, &block)
  # {{{
    db_result = @select_strategy.select(what, &block)
    row = db_result.get_row
    return row.first if row.first
    return {}
  end # }}}
  
  def self.select_values(*what, &block) 
  # {{{
    what = what.first if what.length < 2
    @select_strategy.select(what, &block).get_rows
  end # }}}

  # Same as select, but returns scalar value. 
  def self.polymorphic_select_value(what, &block)
  # {{{
    db_result = @select_strategy.select(what, true, &block)
    row = db_result.get_row
    return row.first if row.first
    return {}
  end # }}}
  
  def self.polymorphic_select_values(what, &block) 
  # {{{
    @select_strategy.select(what, true, &block).get_rows
  end # }}}
  
  # Wrap explicit select. Example: 
  #  SomeModule::SomeAccessor.explicit_insert({
  #                        table_name_A =>
  #                          {'some_field'=>'2', 
  #                          'other_field'=>'3'}, 
  #                        table_name_A =>
  #                          {'another_field'=>'5'}
  #                       })
  # Note that field in 'field'=>'value' is exactly the 
  # field name in the table (e.g. table_name_A) it holds. 
  def self.explicit_insert(keys)
  # {{{
    @insert_strategy.perform_insert(keys)
  end # }}}
  
  # Wrap default select. Example: 
  #  SomeModule::SomeAccessor.insert({
  #                  'some_field'=>'2', 
  #                  'other_field'=>'3', 
  #                  'another_field'=>'5'
  #                  })
  # Note that field in 'field'=>'value' is exactly the 
  # field name in the table it holds. 
  # Table_Accessor.insert basically resolves an explicit 
  # hash and passes it to Table_Accessor.explicit_insert. 
  def self.insert(keys)
  # {{{
    # Sequence values only are known after insert operation, 
    # so we have to retreive the complete key_hash back from 
    # Table_Inserter.perform_insert: 
    key_hash = @insert_strategy.perform_insert(keys)
    # key_hash has been extended by sequence_values now, so 
    # we return it: 
    key_hash
  end # }}}

  def self.distribute_attrib_values(attrib_values)
  # {{{
    values = {}
    # Predefine
    attrib_name_array = []
    # distribute attrib names to tables: 
    @__attributes__.fields().each_pair { |table, attribs|
      table_values = {}
      attrib_name_array = []

      attrib_values.each_pair { |attrib_name, attrib_value|
        attrib_name_array   = attrib_name.split('.') unless attrib_name.instance_of?(Symbol)
        attrib_name_array ||= []
        attrib_short_name   = false
        if attrib_name_array.at(2)
          attrib_short_name = attrib_name_array.at(2)
        else
          attrib_name = attrib_name.to_sym
        end
        
        if attribs.include? attrib_name then
          table_values[attrib_name] = attrib_value
        elsif attrib_short_name && 
              attribs.include?(attrib_short_name) &&
              table == "#{attrib_name_array.at(0)}.#{attrib_name_array.at(1)}" then
          table_values[attrib_name_array.at(2)] = attrib_value
        end
      }
      values[table] = table_values
    }
    values
  end # }}}
 
  # Returns a new Table_Accessor instance by inserting given attribute 
  # values into db and returning an instance for further operations. 
  def self.create(attrib_values={})
  # {{{
    attrib_values[:concrete_model] = self.to_s 
    before_create(attrib_values)

    input_filters = @__filters__.input_filters
    attrib_key  = ''
    attrib_name = ''

    attrib_values.each_pair { |attrib_name, attrib_value|
      if attrib_name.instance_of? Symbol then 
        attrib_key = attrib_name
      else 
        attrib_key = attrib_name.split('.')[-1].to_sym
      end
      
      if (input_filters && input_filters[attrib_key]) then
        attrib_values[attrib_name] = input_filters[attrib_key].call(attrib_value) 
      end
    }
    after_filters(attrib_values)
    
    values = distribute_attrib_values(attrib_values)
    
    before_validation(values)
    if @__associations__.polymorphics then
      Lore.logger.debug { "Polymorphic create on #{self.to_s}" }
      @__associations__.polymorphics.each_pair { |table, model_field|
        values[table][model_field] = self.to_s
      }
    end
    Lore::Validation::Parameter_Validator.validate(self, values)

    before_insert(attrib_values)

    # retreive all final attrib values after insert: (this way, also 
    # sequence values are resolved): 
    
    attrib_values = @insert_strategy.perform_insert(values)
    
    # This would be a double check, as self.load already filters 
    # non-primary key attributes
    select_keys = Hash.new
    @__associations__.primary_keys[table_name].each { |key|
      select_keys["#{table_name}.#{key}"] = attrib_values[table_name][key]
    }
    
    obj = self.load(select_keys)
    raise ::Exception.new("Could not load created instance of #{self.to_s}: #{select_keys.inspect}") unless obj
    after_create(obj)
    
    return obj
  end # }}}
  
  private

  def self.keys_to_select_clause(keys)
    select_keys = {}
    value = false
    @__associations__.primary_keys.each_pair { |table, pkeys| 
      pkeys.each { |attrib_name|
        full_attrib_name = "#{table}.#{attrib_name}"
        value   = keys[full_attrib_name]   # The more explicit, the better. 
        value ||= keys[attrib_name.to_sym] # Symbols are supposed to be most frequently used
        value ||= keys[attrib_name.to_s] 
        select_keys[full_attrib_name] = value unless value.nil?
      }
    }

    return false if select_keys.empty? 
    
    # We have to perform a select here instead of returning 
    # the instance with given attribute values, as this is the 
    # only way to retreive attribute values set in the DB via
    # default values, triggers, etc.
    c = Clause.new
    select_keys.each_pair { |k,v|
      c & (Clause.new(k.to_s.dup) == v.to_s)
    }
    return c
  end

  public

  # Return new Table_Accessor instance by loading an existing entry from 
  # table if present, or false if no entry has been found. 
  # Accepts any combination of :primary_key => 'value'
  # Also allows inherited primary keys. 
  def self.load(keys)
  # {{{
    before_load(keys)

    clause = keys_to_select_clause(keys)
    return false unless clause

    instance = self.select { |inst|
      inst.where(clause)
      inst.limit(1)
    }.first

    return false unless instance
    return instance
  end # }}}

  # Same as Table_Accessor.load, but performing a polymorphic select 
  # on this model. 
  # Also see Table_Accessor.polymorphic_select(). 
  def self.load_polymorphic(keys)
  # {{{ 
    before_load(keys)

    clause = keys_to_select_clause(keys)
    return false unless clause

    instance = polymorphic_select { |inst|
      inst.where(clause)
      inst.limit(1)
    }.first

    return false unless instance
    return instance
  end # }}}

  # Load an instance by only providing primary key values. 
  # This is useful for polymorphic treatment of models, as 
  # you don't have to know about primary key names. 
  #
  # Example: 
  #
  #   The_Model.get(123)
  #
  # Resolves to 
  #
  #   The_Model.load(:the_model_id => 123)
  #
  # If there is more than one primary key attribute, 
  # key values have to be provided in the same order they 
  # are specified in the database. 
  #
  def self.get(*key_values)
  # {{{
    pkeys = {}
    get_primary_keys[table_name].uniq.each_with_index { |pkey, idx|
      pkeys[pkey] = key_values.at(idx)
    }
    load(pkeys)
  end # }}}

  # Delete this object and use Table_Deleter to delete its entity tuple
  # from database. 
  def self.delete(value_keys=nil, &block)
  # {{{
    if value_keys then
      before_delete(value_keys)
      @delete_strategy.perform_delete(value_keys)
      after_delete(value_keys)
    else 
      @delete_strategy.block_delete(&block)
    end
  end # }}}

  private
  
  # Send a hollow query to db, thus only field names are returned. 
  # This works (and has to work) on empty tables, too. 
  # 
  # For every attribute, a class method with the attribute's name is defined
  # in order to retreive the absolute field name (schema.table.field) by calling
  # Table_Accessor.field
  def self.init_model()
  # {{{
    Lore::Context.enter(@context) unless @context.nil?
    begin
      fields_result = Lore::Connection.perform("SELECT * FROM #{@table_name} WHERE false")
    ensure
      Lore::Context.leave unless @context.nil?
    end
    @__attributes__   = Attribute_Settings.new(self, 
                                               fields_result.field_names(), 
                                               fields_result.field_types())

    @__associations__ = Associations.new(self)

    @__filters__      = Filters.new(self)
    @__attributes__.types.each_pair { |table, attributes|
      attributes.each_pair { |field,type|
        input_filter  = Lore::Type_Filters.in[type]
        output_filter = Lore::Type_Filters.out[type]
        @__filters__.add_input_filter(field, &input_filter) if input_filter
        @__filters__.add_output_filter(field, &output_filter) if output_filter
      }
    }

    @select_strategy  = Table_Select.new(self)
    @insert_strategy  = Table_Insert.new(self)
    @delete_strategy  = Table_Delete.new(self)
    @update_strategy  = Table_Update.new(self)

    define_attribute_clause_methods()
  end # }}}

  def self.define_attribute_clause_methods
  # {{{
    if !@context.nil? then
      Lore::Context.enter(@context) 
      context_switched = true
    end
    if @__attributes__[@table_name] then
      @__attributes__[@table_name].each { |attribute|
      # Only define methods on own attributes or on 
      # attributes only a parent Table_Accessor provides: 
      attribute_type = @__attributes__.types[@table_name][attribute]
      method = 
      "def self.#{attribute}() 
        Clause.new('#{@table_name}.#{attribute}', '', '', { :add_types => [ #{attribute_type}], :add_name => '' })
      end"
      class_eval(method)

      "def #{attribute}() 
        attr(:#{attribute})
      end"
      class_eval(method)

      method = 
      "def set_#{attribute}(value) 
        set_attribute_value(:#{attribute.to_s}, value)
      end"
      class_eval(method)

      method = 
      "def #{attribute}=(value) 
        set_attribute_value(:#{attribute.to_s}, value)
      end"
      class_eval(method)
    }
    end
    Lore::Context.leave if context_switched

  end # }}}

  # Meta-programs class instance methods for accessing types
  # associated via has_a. 
  def self.define_entity_access_methods(accessor, foreign_keys, type_name=nil)
  # {{{
    type_name = accessor.to_s.split('::').at(-1).downcase unless type_name

    define_method(type_name) { 

      has_a_keys = Hash.new
      foreign_keys.each { |foreign_key|
        # self.<foreign_key> will return corresponding value 
        # no matter if this klass or a super klass is holding it
        has_a_keys[accessor[foreign_key]] = self.__send__ foreign_key
      }
      return accessor.load(has_a_keys)
    }
    
    define_method("set_#{type_name}") { |other|
      foreign_keys.each { |foreign_key|
        # other.<foreign_key> will return corresponding value 
        # no matter if this klass or a super klass is holding it
        self[foreign_key] = other.pkey
      }
    }
    
    define_method("#{type_name}=") { |other|
      self.__send__("set_#{type_name}", other)
    }

    define_method("set_#{type_name}!") { |other|
      self.__send__("set_#{type_name}", other)
      self.__send__("commit")
    }
  end # }}}

  # Meta-programs class instance methods for accessing types
  # associated via has_n. 
  def self.define_entities_access_methods(accessor, values)
  # {{{
    type_name = accessor.to_s.split('::').at(-1).downcase unless type_name
    
    define_method('add_'+type_name) { |values|
      values.update(get_primary_key_values)
      accessor.create(values)
    }
    define_method(type_name+'_list') {
      foreign_key_values = Hash.new

      accessor.get_foreign_keys[self.table_name].each { |key|
        foreign_key_values[key] = get_attribute_value[key]
      }
      accessor.all_with(foreign_key_values)
    } 
    
    define_method("remove_#{type_name}") { |*keys|
      # For usage: 
      #  Car.remove_wheel(wheel_obj)
      #
      if keys.length == 1 && keys.first.respond_to?(:pkey) then
        keys = [ keys.first.pkey ]
      end
    }

  end # }}}


end # class

end # module Lore
