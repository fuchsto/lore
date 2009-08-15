
require('lore')

module Lore

  module Polymorphic_Class_Methods

    def is_polymorphic(key=:concrete_model)
      @polymorphic_attribute = key.to_sym
      @is_polymorphic = true
    end

    def is_polymorphic?
      (@is_polymorphic == true)
    end

    def select_polymorphic(clause=nil, &block)
      base_entities = select(clause, &block)
      base_entities.map { |e|
        cmodel = e.get_concrete_model
        if cmodel then
          e = cmodel.load(get_primary_keys[table_name].first => e.id()) 
        else 
          e = false
        end
        e
      }
    end

  end

  module Polymorphic_Instance_Methods

    def get_concrete_model
      concrete_model_name = self.__send__(:concrete_model)
      return unless concrete_model_name
      eval(concrete_model_name)
    end

  end

end
