
module Lore
module Behaviours

  module Lockable

    # Defines which attribute to use for locking. 
    # Usage: 
    #
    #   class My_Model < Lore::Model
    #   extend Lockable
    #   include Lockable_Entity
    #     
    #     # ...
    #     lock_by(:lock_field)
    #
    #   end
    #
    #   my_model_entity.lock! 
    #   # same as
    #   My_Model.lock!(my_model_entity)
    #
    def lock_by(attrib)
      @lock_attr = attrib
      @lock_attr_name = attrib.to_s.split('.')[-1].intern
    end
    
    def lock!(inst)
      inst.attr[@lock_attr] = true
      commit
    end # def
    def release!(inst)
      inst.attr[@lock_attr] = false
      commit
    end # def
    def locked?(inst)
      (inst.attr[@lock_attr] == true) || (inst.attr[@lock_attr] == 't')
    end # def

  end # module

  module Lockable_Entity
    def lock!
      self.class.lock!(self)
    end
    def release!
      self.class.release!(self)
    end
    def locked?
      self.class.locked?(self)
    end
  end

end # module
end # module
