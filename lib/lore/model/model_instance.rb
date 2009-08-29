
require('lore/exceptions/ambiguous_attribute')
require('lore/model/polymorphic')

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

  def update_values
    @update_values
  end
  def update_pkey_values
    @update_pkey_values
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
    @primary_key_values
  end

  # Returns primary key values mapped to table names. 
  def get_primary_key_value_map
  # {{{
    return @primary_key_value_map if (@primary_key_value_map && !@touched)
    
    accessor    = self.class
    base_models = accessor.__associations__.base_klasses()
    table_name  = accessor.table_name
    pkey_fields = accessor.get_primary_keys
    
    if !pkey_fields[table_name] then
      raise ::Exception.new("Unable to resolve pkey fields for #{self.class.to_s}. Known fields are: #{pkey_fields.inspect}")
    end

    @primary_key_value_map = { table_name => {} }
    pkey_fields[table_name].each { |own_pkey|
      @primary_key_value_map[table_name][own_pkey] = @attribute_values_flat[own_pkey]
    }
    
    # Map own foreign key values back to foreign primary key 
    # values. This is necessary as joined primary key field names are 
    # shadowed. 
    accessor.__associations__.pkey_value_lookup.each { |mapping|
      foreign_pkeys = {}
      mapping.at(1).each_with_index { |fkey,idx|
        value = @attribute_values_flat[fkey]
        foreign_pkeys[mapping.at(2).at(idx)] = value 
      }
      @primary_key_value_map[mapping.at(0)] = foreign_pkeys
    }
    return @primary_key_value_map
  end # }}}

  # Returns primary key values of own table
  def key
    get_primary_key_value_map[self.class.table_name]
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
    (@touched === true)
  end

  def touch(attrib_name=nil)
    @touched = true
    @touched_fields ||= []
    @touched_fields << attrib_name if attrib_name
    @primary_key_value_map = false
    @primary_key_values    = false
  end

  def untouch(attrib_name=nil)
    @touched = false
    @touched_fields.delete(attrib_name) if attrib_name
  end

  def method_missing(meth, *args)
    return @attribute_values_flat[meth]
  end

  alias :obj_id :id if respond_to?(:id)
  def id
    @attribute_values_flat[:id] || obj_id
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

    # touch(attrib_name)
    @touched = true
    @touched_fields ||= []
    @touched_fields << attrib_name if attrib_name

    @attribute_values_flat[attrib_name.to_sym] = attrib_value
  end # def }}}

  def set_attribute_values(value_hash)
    value_hash.each_pair { |attrib_name,value|
      if @input_filters && @input_filters.has_key?(attrib_name.intern) then
        value_hash[attrib_name] = @input_filters[attrib_name.intern].call(attrib_value)
      end
      @attribute_values_flat[attrib_name.to_sym] = attrib_value
      @touched_fields << attrib_name.intern
    }
    touch
  end

  # Sets attribute value. Example: 
  #   instance[:name] = 'Wombat'
  #   instance.commit
  alias :[]= set_attribute_value

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
  def get_attribute_values() 
    @attribute_values_flat
  end # def

  # Returns attribute values mapped to table names. 
  def get_attribute_value_map
    return @attribute_values if @attribute_values
    @attribute_values = self.class.distribute_attrib_values(@attribute_values_flat)
    return @attribute_values
  end

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
    Lore.logger.warn { 'abs_attr() is deprecated' }

    klass = klass.to_s if klass.instance_of? Symbol
    return @attribute_values if klass.nil?
    return @attribute_values[klass.table_name] if klass.kind_of? Lore::Table_Accessor
    return @attribute_values[klass] if klass.instance_of? String
    return @attribute_values[klass.to_s.split('.')[0..1].join('.').to_s][klass.to_s.split('.').at(-1)] if klass.instance_of? Lore::Clause
  end # def

  def attribute_values
    @attribute_values ||= self.class.distribute_attrib_values(@attribute_values_flat)
    @attribute_values
  end
  
  # Commit changes on Table_Accessor instance to DB. 
  # Results in one or more SQL update calls. 
  #
  # Common usage: 
  # 
  #   unit.name = 'changed'
  #   unit.commit() 
  # 
  def commit
  # {{{
    return unless @touched
    
    Lore.logger.debug { "Updating #{self.to_s}. " }
    Lore.logger.debug { "Touched values are: #{@touched_fields.inspect}" }

    # TODO: Optimize this! 
    @attribute_values = self.class.distribute_attrib_values(@attribute_values_flat)
    foreign_pkey_values = false
    @update_values = {}
    @update_pkey_values = {}
    @attribute_values.each_pair { |table,attributes|
      @touched_fields.each { |name|
        value  = @attribute_values[table][name]
        filter = self.class.__filters__.input_filters[name]
        value = filter.call(value) if filter
        if attributes[name] then
          update_values[table] ||= {}
          @update_values[table][name] = value 
        end
      }
      foreign_pkey_values = get_primary_key_value_map[table]
      
      @update_pkey_values[table] = foreign_pkey_values if foreign_pkey_values
    }

    Validation::Parameter_Validator.validate_update(self.class, update_values)

    self.class.before_commit(self)
    self.class.__update_strategy__.perform_update(self)
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

    self.class.__delete_strategy__.perform_delete(@attribute_values_flat)
    # Called after entity_instance.delete
    self.class.after_instance_delete(self)
  end # def

  def inspect
  # {{{
    'Lore::Table_Accessor entity: ' << @attribute_values_flat.inspect
  end # }}}
  
end # module

end # module
