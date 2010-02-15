require('rubygems')

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

  # Implements lazy polymorphism. 
  # Assuming model 'Content' is polymorphic, and 'Article' and 
  # 'Image' are derived from it, eager polymorphic loads look like 
  # this: 
  #
  #   Content.find(10).polymorphic.with(...).entities
  #
  # Method #polymorphic has to be called somewhere between #find 
  # and a kicker, like #entities or #to_a. 
  #
  # Lazy polymorphism only loads the abstract model's instances: 
  #
  #   contents = Content.find(10).with(...).entities
  #
  # Variable 'contents' no holds up to 10 Content entities. 
  # To resolve them to their concrete (Article or Image) instances: 
  #
  #   contents.map { |c| c.concrete_instance } 
  #
  # Of course, this means N+1 queries (one for 10 content instances, 
  # then 1 for each content instance, so 1+10 = 11 queries), but 
  # sometimes this is better than joining against every possible 
  # concrete model table. In case there are 5 concrete models 
  # derived from Content, 11 tiny queries could be better than one 
  # joining againt 5 models - including all of their implicitly 
  # aggregated tables. 
  #
  def concrete_instance
    if !self.class.is_polymorphic? then
      raise ::Exception.new("#{self.class} is not polymorphic?")
    end
    cmodel = get_concrete_model()
    if cmodel then
      return cmodel.load(key())
    else
      raise ::Exception.new("Could not find concrete model #{cmodel.inspect} for #{self.class}")
    end
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
  alias pkeys get_primary_key_values

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
    if !@label_string || touched? then
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
    if attrib_name then
      @touched_fields ||= []
      @touched_fields << attrib_name 
    end
    @primary_key_value_map = false
    @primary_key_values    = false
  end

  def untouch(attrib_name=nil)
    @touched = false
    @touched_fields.delete(attrib_name) if attrib_name
  end

  alias :obj_id :id if respond_to?(:id)
  def id
    @attribute_values_flat[:id] || obj_id
  end

  def method_missing(meth, *args)
    return @attribute_values_flat[meth] unless meth.to_s[-1] == '='
    set_attribute_value(meth.to_s[0..-2].to_sym, args.first)
  end

  # Set value for given attribute, e.g. for later commit. 
  # It is recommended to use random access assignment instead: 
  #
  #   instance.set_attribute_value(:name, 'Wombat')
  # is same as
  #   instance[:name] = 'Wombat'
  #
  def set_attribute_value(attrib_name, attrib_value=nil)
    return set_attribute_values(attrib_name) if attrib_name.is_a? Hash 
    touch(attrib_name)
    @attribute_values_flat[attrib_name.to_sym] = attrib_value
  end 
  # Sets attribute value. Example: 
  #   instance[:name] = 'Wombat'
  #   instance.commit
  alias []= set_attribute_value

  def set_attribute_values(value_hash)
    value_hash.each_pair { |attrib_name, value|
      touch(attrib_name)
      @attribute_values_flat[attrib_name.to_sym] = value
    }
  end
  alias set set_attribute_values

  # Returns true if instance points to same records as other instance. 
  # Only compares primary key values. 
  def ==(other)
    return false if self.class.to_s != other.class.to_s
    return pkeys() == other.pkeys()
  end

  # Return primary key value. In case primary key is composed, return it as array. 
  def pkey
    table = self.class.table_name
    key   = get_primary_key_values.first
    return key
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
  alias attribute_value get_attribute_values

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

  # Explicit attribute request using given model klass. 
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
  # Example: 
  #   Car[Vehicle.name]
  #
  # In case name is attribute field in Car and Vehicle. 
  #
  def abs_attr(klass=nil)
    Lore.logger.warn { 'abs_attr() is deprecated' }

    klass = klass.to_s 
    @attribute_values ||= attribute_values()

    return @attribute_values if klass.nil?
    case @attribute_values
    when Lore::Table_Accessor: 
      return @attribute_values[klass.table_name] 
    when String: 
      return @attribute_values[klass] 
    when Lore::Clause: 
      return @attribute_values[klass.split('.')[0..1].join('.')][klass.split('.').last] 
    end

  end 
  alias [] abs_attr

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
  # Returns true if instance record has been updated, 
  # or false if no changes had to be committed. 
  #
  def commit
  # {{{
    Lore.logger.debug { "Not updating instance as not touched" } unless @touched
    return false unless @touched
    
    Lore.logger.debug { "Updating #{self.to_s}. " }
    Lore.logger.debug { "Touched values are: #{@touched_fields.inspect}" }

    @touched_fields.uniq!
    return false if @touched_fields.length == 0

    # TODO: Optimize this! 
    @attribute_values = self.class.distribute_attrib_values(@attribute_values_flat)
    foreign_pkey_values = false
    @update_values = {}
    @update_pkey_values = {}
    @attribute_values.each_pair { |table,attributes|
      @touched_fields.each { |name|
        value  = @attribute_values[table][name]
        filter = self.class.__filters__.input_filters[name]
        value  = filter.call(value) if filter
        if !attributes[name].nil? then
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

    return true
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
    self.class.to_s + ' entity: ' << @attribute_values_flat.inspect
  end # }}}
  
  def label
    @attribute_values_flat[table_accessor.get_label.to_sym]
  end

end # module

end # module
