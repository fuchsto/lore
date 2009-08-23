
module Lore

  # There are several categories of attributes: 
  #
  # [required] - A value for this attribute has to be set in any case 
  #              (field is NOT NULL)
  # [implicit] - Value for this attribute will be set by database. 
  #              (field is set via sequence, trigger, etc.)
  #              Any given value will be ignored. 
  #
  # If none of the above, field will be treaded as NULL field. 
  #
  class Attribute_Settings

    attr_accessor :fields, :fields_flat, :required, :implicit, :types, :constraints, :sequences, :primary_keys
    
    def initialize(accessor, fields, types)
      fields.map! { |a| a.to_sym }
      @accessor           = accessor
      fields.map! { |f| f.to_sym } 
      @fields             = { accessor.table_name => fields }
    # @fields_flat        = fields
      @required           = {}
      @implicit           = {}
      @types              = {}
      @constraints        = {}
      @hidden             = {}
      @sequences          = {}
      @primary_keys       = {}
      sym_types = {}
      types.each_pair { |attrib, type|
        sym_types[attrib.to_sym] = type
      }
      @types[accessor.table_name] = sym_types
    end

    def [](table_name)
      @fields[table_name]
    end

    def num_fields
      fields_flat.length
    end
    def num_own_fields
      fields[@accessor.table_name].length
    end

    def required?(attribute)
      # Inherited primary keys are marked as required, 
      # but they aren't in this model, where they are 
      # also marked as implicit. 
      @required[attribute] && !@implicit[attribute] || false
    end
    def implicit?(attribute)
      @implicit[attribute] 
    end

    def set_required(*args)
      table = @accessor.table_name
      if args.length == 1 then
        attribute = args.at(0)
      else 
        table     = args.at(0)
        attribute = args.at(1)
      end
      @required[table] = {} unless @required[table]
      @required[table][attribute.to_sym] = true
    end

    # Implicit attributes are set by the DBMS, via sequences, 
    # triggers, or may not be set manually for some reason. 
    # Manually set values for implicit attributes are ignored 
    # on INSERT and UPDATE commands, but may be used in e.g. 
    # WHERE part of a query. 
    #
    # Usage: 
    #  
    #   set_implicit(table, :attrib_a)
    # Or 
    #   set_implicit(:attrib_a)  # table defaults to own table
    #
    def set_implicit(*args)
      table     = nil
      attribute = nil
      if args.length > 1 then 
        table     = args.at(0)
        attribute = args.at(1).to_sym
      else
        table     = @accessor.table_name
        attribute = args.at(0).to_sym
      end
      @implicit[table] = [] unless @implicit[table]
      @implicit[table] << attribute
    end

    def add_primary_key(attribute, sequence_name=nil)
      @primary_keys[@accessor.table_name] = [] unless @primary_keys[@accessor.table_name]
      @primary_keys[@accessor.table_name] << attribute
      if sequence_name then
        set_sequence(attribute, sequence_name) if sequence_name
      else
        set_required(attribute)
      end
    end

    def set_sequence(attribute, sequence_name)
      set_implicit(attribute)
      if @sequences[@accessor.table_name] then
        @sequences[@accessor.table_name][attribute] = sequence_name
      else
        @sequences[@accessor.table_name] = { attribute => sequence_name } 
      end
    end

    # All attributes that aren't implicit and thus 
    # can be set manually. 
    def explicit
      return @explicit if @explicit
      @explicit = {}
      @fields.each_pair { |table, attrib_list| 
        @explicit[table] = attrib_list.reject { |a| 
          # @fields includes all inherited fields. 
          # We do not want to aggregated models to 
          # extend @expected and @implicit, as they 
          # can only be referenced by their primary 
          # keys, but never assigned values in e.g. 
          # Model.create. 
          !@implicit[table] || @implicit[table].include?(a.to_sym)
        }
      }
      @explicit.delete_if { |table, fields| fields.length == 0 }
      @explicit
    end

    def add_hidden(attribute)
      @hidden[@accessor.table_name] = attribute
    end

    def add_base_model(model)
      inherit(model)
      @sequences.update(model.__attributes__.sequences)
      @implicit.update(model.__attributes__.implicit)
      @required.update(model.__attributes__.required)
      @fields_flat = false # Invalidate cached values
    end

    def add_aggregate_model(model)
      inherit(model)
      # Include indirect implicit fields, but do not 
      # set aggregated primary keys as implicit, as it 
      # will be set manually: 
      aggregated_implicit = model.__attributes__.implicit.dup
    # model.get_primary_keys.each { |pkey_field|
    #   aggregated_implicit[model.table_name].delete(pkey_field)
    # }
    # @implicit.update(aggregated_implicit)
      @fields_flat = false # Invalidate cached values
    end

    def fields_flat
      return @fields_flat if @fields_flat
      fields = @fields[@accessor.table_name]
      fields += fields_flat_rec
      # Shadowing attribute fields whose name is already 
      # present in more specific table. Remove uniq! to 
      # allow multiple appearance of attribute names in 
      # flat field list. 
      # TODO: CHECK THIS!!
      # fields.uniq!
      @fields_flat = fields
      return @fields_flat
    end

    def fields_flat_rec(model=nil)
      fields = []
      model ||= @accessor
      joined_models = model.__associations__.joined_models
      model.__associations__.joins.each_pair { |table,base_tables|
        fields += @fields[table]
        fields += fields_flat_rec(joined_models[table].first)
      }
      fields
    end
    
    def inherit(base_model)
      parent_attributes = base_model.__attributes__
      @constraints.update(parent_attributes.constraints)
      @types.update(parent_attributes.types)
      @fields.update(parent_attributes.fields)
    # @fields_flat += parent_attributes.fields_flat
      @primary_keys.update(parent_attributes.primary_keys)
    end

    def add_constraints(attrib, constraints={})
      if attrib.kind_of? Clause then
        attrib_split = attrib.to_s.split('.')
        table        = attrib_split[0..-2]
        attrib       = attrib_split[-1]
      else
        table = @accessor.table_name
      end
      attrib = attrib.to_sym unless attrib.is_a? Symbol

      @constraints[table]         = Hash.new unless @constraints[table]
      @constraints[table][attrib] = Hash.new unless @constraints[table][attrib]

      if constraints[:mandatory] then
        set_required(table, attrib.to_s)
      end
      if constraints[:format] then
        @constraints[table][attrib][:format] = constraints[:format]
      end
      if constraints[:length] then
        if constraints[:length].kind_of? Range then
          @constraints[table][attrib][:minlength] = constraints[:length].first
          @constraints[table][attrib][:maxlength] = constraints[:length].last
        else 
          @constraints[table][attrib][:minlength] = constraints[:length]
          @constraints[table][attrib][:maxlength] = constraints[:length]
        end
      end
      if constraints[:minlength] then
        @constraints[table][attrib][:minlength] = constraints[:minlength]
      end
      if constraints[:maxlength] then
        @constraints[table][attrib][:maxlength] = constraints[:maxlength]
      end
    end
    
  end

end
