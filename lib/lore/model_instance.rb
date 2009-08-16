
require('lore/exception/ambiguous_attribute')
require('lore/behaviours/movable')
require('lore/behaviours/versioned')
require('lore/behaviours/lockable')
require('lore/polymorphic')

module Lore

class Attribute_Hash < Hash # :nodoc: 
  
  alias random_access_op []
  alias random_access_assign_op []=
  def [](key)
    if !random_access_op(key).nil? then
      return random_access_op(key)
    elsif !random_access_op(key.to_s).nil? then
      return random_access_op(key.to_s)
    else
      return random_access_op(key.to_s[0..24].to_sym)
    end
  end

  def []=(key, value)
    begin
      key = key.to_s[0..24].to_sym
    rescue ::Exception => excep
      Lore.logger.debug { 'Error when trying to access attribute ' << key.inspect }
      raise excep
    end
    self.random_access_assign_op(key, value)
  end

  def method_missing(key) 
    self[key]
  end
  
end # class

# Used as mixin for Table_Accessor. 
# This module holds methods provided by Table_Accessor instances. 
module Model_Instance
  include Polymorphic_Instance_Methods


  def table_accessor
    self.class
  end

  # Create a marshalled dump of this model instance. 
  # Returns attribute values as The only difference 
  # between model instances is their value set. 
  def marshal_dump
    { 
      :klass => self.class.to_s, 
      :values => @attribute_values_flat, 
      :joined => @joined_models
    }
  end

  # Creates an instance of self from marshalled value set. 
  def marshal_load(dump)
    return initialize(dump[:values], dump[:joined], :cached)
  end

  # Whether this instance has been loaded from 
  # cache or live from DB. 
  def is_cached_entity?
    # Set in initialize via marshal_load
    @loaded_from_cache
  end
  
  def get_primary_key_values
    return @primary_key_values if @primary_key_values

    keys = self.class.get_primary_keys[self.class.table_name]
    @primary_key_values = keys.map { |pkey|
      @attribute_values_flat[pkey]
    }

    # Before refactoring, attribute values have been 
    # distributed to tables: 
    # @primary_key_values = Hash.new
    # self.class.get_primary_keys.each_pair { |table, attrib_array|
    #   puts 'resolving for ' << table
    #   @primary_key_values[table] = Hash.new
    #   attrib_array.each { |field|
    #       puts 'looking up value for ' << field.inspect
    #       pk_attrib_value   = @attribute_values[table][field]
    #       # Postgres does not allow field names longer than 25 chars, 
    #       # and cuts them otherwise: 
    #       pk_attrib_value ||= @attribute_values[table][field.to_s[0..24]] 
    #       @primary_key_values[table][field] = pk_attrib_value
    #   }
    # }
    @primary_key_values
  end

  # Returns primary key values of own table
  def key
    @primary_key_values[self.class.get_table_name]
  end

  def get_label_string
    if !@label_string || @touched then
      value = ''
      self.class.get_labels.each { |label_attrib|
        label_parts = label_attrib.split('.')
        value << @attribute_values[label_parts[0..1].join('.')][label_parts[2]].to_s + ' '
      }
      value = '[no label given]' if value == ''
      @label_string = value
    end
    return @label_string
  end


  def touched?
    @touched
  end

  def method_missing(meth, *args)
    return @attribute_values_flat[meth]
  end
  def id
    @attribute_values_flat[:id]
  end

  # Set value for given attribute, e.g. for later commit. 
  # It is recommended to use random access assignment instead: 
  #
  #   instance.set_attribute_value(:name, 'Wombat')
  # is same as
  #   instance[:name] = 'Wombat'
  #
  def set_attribute_value(attrib_name, attrib_value)
  # {{{

    if @input_filters && (@input_filters.has_key?(attrib_name.intern)) then
      attrib_value = @input_filters[attrib_name.intern].call(attrib_value)
    end

    @touched = true
    # Delete cached value of @flat_attr: 
    @flat_attr = nil 
    save_attribute_values = @attribute_values.dup
    attrib_name = attrib_name.to_s
    attrib_name_array = attrib_name.split('.')
    
    # Attrib name is implicit (no table name given). 
    # Check for ambiguous attribute name: 
    if attrib_name_array[2].nil? then
      changed_table = false
      @attribute_values.each { |table, attributes|
        
        if attributes.has_key?(attrib_name) then
          @attribute_values[table][attrib_name] = attrib_value
          changed_table = true
        elsif attributes.has_key?(attrib_name) && changed_table then
          raise Lore::Exception::Ambiguous_Attribute.new(table, 
                                                         changed_table, 
                                                         attrib_name)
        end
      }
      
    # Attrib name is explicit (also includes table name). 
    # No need to check for ambiguous attribute: 
    else 
      attrib_name_index = attrib_name_array[2]
      attrib_table      = attrib_name_array[0]+'.'+attrib_name_array[1]

      if @attribute_values[attrib_table] && @attribute_values[attrib_table][attrib_name_index] then
        @attribute_values[attrib_table][attrib_name_index] = attrib_value
      else 
      # raise ::Exception.new("#{self.class.to_s} does not have attribute #{attrib_table}.#{attrib_name_index}")
      end
    end
  end # def }}}

  # Sets attribute value. Example: 
  #   instance[:name] = 'Wombat'
  #   instance.commit
  def []=(key, value)
    set_attribute_value(key, value)
  end

  # Explicit attribute request. 
  # Example: 
  #   Car[Vehicle.name]
  # In case name is attribute field in Car and Vehicle. 
  def [](clause)
    abs_attr(clause)
  end

  # Returns true if instance points to same records as other instance. 
  # Only compares primary key values. 
  def ==(other)
    return false if self.class.to_s != other.class.to_s
    return pkeys() == other.pkeys()
  end

  # Return primary key value. In case primary key is composed, return it as array. 
  def pkey
    table = self.class.table_name
    key = get_primary_key_values
    return key.first if key.length < 2
    return key
  end

  def pkeys
    table = self.class.table_name
    return get_primary_key_values
  end

  # Returns true if instance points to same records as other instance, 
  # also compares non-key attribute values. 
  def ===(other)
    return false unless (self == other)
    
  end
  # See ==
  def <=>(other)
    return !(self.==(other))
  end
  
  # Returns all attribute values as hash. 
  def get_attribute_values() # :nodoc:
    @attribute_values_flat
  end # def

  # Returns value hash of instance attributes like: 
  #
  #   {
  #     'schema.table.id' => 123, 
  #     'schema.atable.name' => 'example'
  #   }
  #
  # Common usage: 
  # 
  #   table_instance.attr[:id]  ->  123
  #
  # But it is recommended to use 
  #
  #   table_instance.id  -> 123
  #
  def attr
    return @attribute_values_flat
    if @flat_attr.nil? then
      @flat_attr = Attribute_Hash.new
      @attribute_values.each_pair { |table, attribs| 
        attribs.each_pair { |attrib_name, value|
          @flat_attr[attrib_name] = value unless value.nil?
        }
      }
    end
    @flat_attr
  end # def

  # Returns value hash of instance attributes 
  # of a given subtype like: 
  #
  #   {
  #     'id' => 123, 
  #     'name' => 'example'
  #   }
  #
  # Common usage: 
  # 
  #   self.class.abs_attr(Klass_A)[:id]  ->  123
  #
  def abs_attr(klass=nil)
    raise ::Exception.new('abs_attr() is deprecated')

    klass = klass.to_s if klass.instance_of? Symbol
    return @attribute_values if klass.nil?
    return @attribute_values[klass.table_name] if klass.kind_of? Lore::Table_Accessor
    return @attribute_values[klass] if klass.instance_of? String
    return @attribute_values[klass.to_s.split('.')[0..1].join('.').to_s][klass.to_s.split('.').at(-1)] if klass.instance_of? Lore::Clause
  end # def

  
  # Commit changes on Table_Accessor instance to DB. 
  # Results in an / several SQL update calls. 
  #
  # Common usage: 
  # 
  #   unit['name'] = 'changed'
  #   unit.commit() 
  # 
  def commit
  # {{{

    return unless @touched
    
    input_filters = self.class.get_input_filters
    if input_filters then
      @attribute_values.each_pair { |table,keys|
        keys.each_pair { |key, value|
          @attribute_values[table][key] = input_filters[key.intern].call(value) if input_filters[key.intern]
        }
      }
    end

    begin
      Lore::Validation::Parameter_Validator.invalid_params(self.class, 
                                                           @attribute_values)
    rescue Lore::Exception::Invalid_Klass_Parameters => ikp    
    # log'n'throw: 
      ikp.log
      raise ikp
    end

    self.class.before_commit(self)

    Table_Updater.perform_update(self.class, self)

    self.class.after_commit(self)

    @touched = false
    
  end # def }}}
  alias save commit

  # Delete this instance from DB. 
  # Common usage: 
  #
  #  unit = Some_Table_Accessor.select { ... }.first
  #  unit.delete
  #   
  # Calls hooks Table_Accessor.before_instance_delete(self)
  # and Table_Accessor.after_instance_delete(self). 
  #
  def delete
    # Called before entity_instance.delete
    self.class.before_instance_delete(self)

    Table_Deleter.perform_delete(self.class, @attribute_values)
    # Called after entity_instance.delete
    self.class.after_instance_delete(self)
  end # def

  def inspect
  # {{{
    'Lore::Table_Accessor entity: ' << @attribute_values.inspect
  end # }}}
  
end # module

end # module
