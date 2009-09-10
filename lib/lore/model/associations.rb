
module Lore

  class Associations

    attr_reader :foreign_keys
    attr_reader :primary_keys 
    attr_reader :base_klasses 
    attr_reader :has_a 
    attr_reader :has_a_keys
    attr_reader :has_n 
    attr_reader :belongs_to 
    attr_reader :aggregate_klasses
    attr_reader :aggregates 
    attr_reader :base_klasses_tree
    attr_reader :join_tables
    attr_reader :aggregates_tree
    # Returns mapping rules from own foreign key values to 
    # foreign primary key values. Supports composed foreign keys. 
    # Example: 
    #   { 
    #     'public.vehicle'   => [ :vehicle_id ], 
    #     'public.motorizes' => [ :motorized_id ] 
    #   }
    #   -->
    #   # Mapping is:  [ <table>, <own key names>, <foreign pkey name> ]
    #   [ 
    #     'public.vehicle',   [ :vehicle_id ], [ :id ], 
    #     'public.motorized', [ :motorizes_id ], [ :id ], 
    #   ]
    # Note that this is an array, not a Hash, and entries are 
    # ordered by join order. 
    # (Which is important as arrays are ordered, opposed to Hashes 
    # in Ruby 1.8)
    #
    # For in-depth understanding, see 
    # Model_Instance#get_primary_key_value_map
    attr_reader :pkey_value_lookup

    # Returns polymorphic base classes as map 
    #   { table => polymorphic_attribute }
    # Example: 
    #  
    #  { 'public.asset' => :concrete_asset_model }
    #
    attr_reader :polymorphics

    attr_reader :concrete_models

    def initialize(accessor)
      @accessor = accessor
      @foreign_keys = {}
      @primary_keys = {}
      
      @has_a = {}
      @has_a_keys = {}
      @has_n = {}
      @belongs_to = {}
      
      @base_klasses = {}
      @base_klasses_tree = {}
      @join_tables = []
      @aggregate_klasses = {}
      @aggregates_tree = {}

      @pkey_value_lookup = []

      @polymorphics = {}
      @concrete_models = []

      @joins = false
    end

    private

    # Add foreign keys to another model. 
    # Assumes foreign keys are stored in the models own table. 
    def add_foreign_key_to(model, *keys)
    # {{{
      keys.flatten! 
      mapping = [ keys, model.__associations__.primary_keys[model.table_name] ]
      @foreign_keys[@accessor.table_name] = {} unless @foreign_keys[@accessor.table_name]
      @foreign_keys[@accessor.table_name][model.table_name] = mapping 
      # Inherit foreign keys: 
      @foreign_keys.update(model.__associations__.foreign_keys)
    end # }}}

    public

    def add_primary_key(attribute, sequence_name=nil)
      @primary_keys[@accessor.table_name] = [] unless @primary_keys[@accessor.table_name]
      @primary_keys[@accessor.table_name] << attribute
    end

    # Add another model as base model. 
    # Leads to inheritance of fields, primary keys, 
    # joins etc. 
    #
    # Used by Model.is_a? Other_Model
    #
    def add_base_model(model, *keys)
    # {{{
      add_foreign_key_to(model, *keys)
      @base_klasses[model.table_name]      = [ model, *keys ]
      @base_klasses_tree[model.table_name] = model.__associations__.base_klasses_tree
      @aggregates_tree[model.table_name]   = model.__associations__.aggregates_tree
      keys.flatten.each { |attribute|
        @accessor.__attributes__.set_implicit(@accessor.table_name, attribute)
      }
      @primary_keys.update(model.__associations__.primary_keys)
      @pkey_value_lookup += model.__associations__.pkey_value_lookup
      @pkey_value_lookup << [ model.table_name, 
                              keys.flatten, 
                              model.__associations__.primary_keys[model.table_name] ]
      if model.is_polymorphic? then
        @polymorphics[model.table_name] = model.polymorphic_attribute
        model.__associations__.add_concrete_model(@accessor)
      end
      @join_tables << model.table_name
      inherit(model)
    end # }}}

    # For polymorphic models only. 
    # Adds a concrete model class for a polymorphic 
    # model. 
    def add_concrete_model(model)
      @concrete_models << model unless @concrete_models.include?(model)
    end

    # Add another model as aggregate model. 
    # Leads to inheritance of fields, primary keys, 
    # joins etc. 
    #
    # Used by Model.aggregates Other_Model
    #
    def add_aggregate_model(model, *keys)
    # {{{
      add_foreign_key_to(model, *keys)
      @aggregate_klasses[model.table_name] = [ model, *keys ]
      @aggregates_tree[model.table_name]   = model.__associations__.aggregates_tree
      # Required attributes of aggregated models are not 
      # required in this model, as aggregated models are 
      # referenced by their pkey only and have to exist 
      # in DB already. 
      # Thus, the foreign key to an aggregated model is
      # required only: 
      keys.flatten.each { |attribute|
        @accessor.__attributes__.set_required(attribute)
      }
      inherit(model)
    end # }}}

    def joined_models()
      @joined_models || @joined_models = @aggregate_klasses.dup.update(@base_klasses)
    end
    alias joined_klasses joined_models

    # Recursively checks if another model is aggregated 
    # by this model, either directly (foreign key is in 
    # own table) or via inheritance (foreign key is in 
    # joined table). 
    def has_aggregate_model?(model)
    # {{{
      @aggregate_klasses.each_pair { |table,map|
        aggr_model = map.first
        if aggr_model == model || 
           aggr_model.__associations__.has_aggregate_model?(model) then
          return true 
        end
      }
      return false
    end # }}}

    # Recursively checks if another model is a base model  
    # of this model, either directly (foreign key is in 
    # own table) or via inheritance (foreign key is in 
    # joined table). 
    def has_base_model?(model)
    # {{{
      @base_klasses.each_pair { |table,map|
        aggr_model = map.first
        if aggr_model == model || 
           aggr_model.__associations__.has_base_model?(model) then
          return true 
        end
      }
      return false
    end # }}}

    # Recursively checks if another model is joined  
    # by this model (aggregated or as base model), either 
    # directly (foreign key is in own table) or via 
    # inheritance (foreign key is in joined table). 
    def has_joined_model?(model)
      has_base_model?(model) || has_aggregated_model?(model)
    end


    def joins()
      @joins || @joins = @aggregates_tree.dup.update(@base_klasses_tree)
    end

    # For cat.get_wheel()
    def add_has_a(model, *keys)
      add_foreign_key_to(model, *keys)
      @has_a[@accessor.table_name] = model
      keys.each { |key|
        @has_a_keys[@accessor.table_name] = { key.first => model }
      }
    end

    # For cat.get_wheel_set()
    def add_has_n(model, *keys)
      add_foreign_key_to(model, *keys)
      @has_n[@accessor.table_name] = model
    end

    # For wheel.get_car()
    def add_belongs_to(model, *keys)
      add_foreign_key_to(model, *keys)
      @belongs_to[@accessor.table_name] = model
    end

    def inherit(base_model)
      parent_associations = base_model.__associations__
      @has_a.update(parent_associations.has_a)
      @has_n.update(parent_associations.has_n)
      @belongs_to.update(parent_associations.belongs_to)
      @join_tables << parent_associations.join_tables
    end

  end

end
