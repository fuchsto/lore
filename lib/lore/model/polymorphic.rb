
require('lore')

module Lore

  class Lore::Table_Accessor
  end

  module Polymorphic_Class_Methods

    def is_polymorphic(key=:concrete_model)
      @polymorphic_attribute       = key.to_sym
      @polymorphic_attribute_index = get_fields_flat.index(key.to_sym)
      @is_polymorphic = true
    end

    def is_polymorphic?
      (@is_polymorphic == true)
    end

=begin

    # DEPRECATED
    #
    # Lazy polymorphic select
    #
    def select_polymorphic(clause=nil, &block)
      base_entities = select(clause, &block)
      base_entities.map { |e|
        cmodel = e.get_concrete_model
        if cmodel then
          e = cmodel.load(get_fields[table_name].first => e.pkey()) 
        else 
          e = false
        end
        e
      }
    end
=end

    def polymorphic_attribute
      @polymorphic_attribute
    end
    def polymorphic_attribute_index
      @polymorphic_attribute_index
    end

  end

  module Polymorphic_Instance_Methods

    def get_concrete_model
      concrete_model_name = self.__send__(self.class.polymorphic_attribute)
      return unless concrete_model_name
      eval(concrete_model_name)
    end

  end

end
