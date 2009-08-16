
module Lore

  class Associations

    attr_reader :foreign_keys, :primary_keys, :base_klasses, :has_a, :has_n, :belongs_to, :aggregate_klasses, :aggregates, :base_klasses_tree, :aggregates_tree

    def initialize(accessor)
      @accessor = accessor
      @foreign_keys = {}
      @primary_keys = {}
      
      @has_a = {}
      @has_n = {}
      @belongs_to = {}
      
      @base_klasses = {}
      @base_klasses_tree = {}
      @aggregate_klasses = {}
      @aggregates_tree = {}

      @joins = false
    end

    private

    def add_foreign_key_to(model, *keys)
      keys.flatten! 
      mapping = [ keys, model.__associations__.primary_keys[model.table_name] ]
      @foreign_keys[@accessor.table_name] = {} unless @foreign_keys[@accessor.table_name]
      @foreign_keys[@accessor.table_name][model.table_name] = mapping 
      keys.each { |key|
        @accessor.__attributes__.set_implicit(@accessor.table_name, key)
      }
    end

    public

    def add_primary_key(attribute, sequence_name=nil)
      @primary_keys[@accessor.table_name] = [] unless @primary_keys[@accessor.table_name]
      @primary_keys[@accessor.table_name] << attribute
    end

    # For Car.is_a Vehicle
    def add_base_model(model, *keys)
      add_foreign_key_to(model, *keys)
      @base_klasses[model.table_name] = [ model, *keys ]
      @base_klasses_tree[model.table_name] = model.__associations__.base_klasses_tree
      @aggregates_tree[model.table_name]   = model.__associations__.aggregates_tree
      keys.each { |attribute|
        @accessor.__attributes__.set_required(attribute)
      }
      inherit(model)
    end

    def add_aggregate_model(model, *keys)
      add_foreign_key_to(model, *keys)
      @aggregate_klasses[model.table_name] = [ model, *keys ]
      @aggregates_tree[model.table_name]   = model.__associations__.aggregates_tree
      keys.each { |attribute|
        @accessor.__attributes__.set_required(attribute)
      }
      inherit(model)
    end

    def joined_models()
      @joined_models || @joined_models = @aggregate_klasses.dup.update(@base_klasses)
    end
    alias joined_klasses joined_models

    def joins()
      @joins || @joins = @aggregates_tree.dup.update(@base_klasses_tree)
    end

    # For cat.get_wheel()
    def add_has_a(model, *keys)
      add_foreign_key_to(model, *keys)
      @has_a[@accessor.table_name] = model
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
    end

  end

end
