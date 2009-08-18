
module Lore
module Behaviours

  # Move an entity within a given criteria range, 
  # e.g. within nodes of a tree. 
  #
  # Usage: 
  #  
  #   class My_Model < Lore::Model
  #   extend Lore::Behaviours::Movable
  #   include Lore::Behaviours::Movable_Entity
  #    # ...
  #    ordered_by(:position)
  #   end
  #
  #   # Will move entity to position 12 within child entries
  #   # of node with id 2: 
  #   my_model_entity.move_to(12, (My_Model.parent_id == 2))
  #   # Same as
  #   My_Model.move(my_model_entity, 12, (My_Model.parent_id == 2))
  #
  module Movable

    def ordered_by(attrib)
      @order_attr = attrib
      @order_attr_name = attrib.to_s.split('.')[-1].intern
    end
    
    def move(inst, sortpos, criteria)
      sortpos = sortpos.to_i
      return if sortpos < 1

      criteria ||= Lore::Clause.new()
      sortpos_old = inst.attr[@order_attr_name].to_i

      # move down: 
      if sortpos.to_i > sortpos_old then
        self.update { |na|
          na.set({@order_attr_name => @order_attr-1}).where(
            (criteria) &
            (@order_attr <= sortpos) &
            (@order_attr > sortpos_old)
          )
        }
      # move up: 
      elsif sortpos.to_i < sortpos_old then
        self.update { |na|
          na.set({@order_attr_name => @order_attr+1}).where(
            (criteria) &
            (@order_attr >= sortpos) &
            (@order_attr < sortpos_old)
          )
        }
      end
      # In case we actually had to move the entity: 
      if sortpos != sortpos_old then
        inst.set_attribute_value(@order_attr_name, sortpos)
        inst.commit()
      end
    end # def
    
  end # module

  module Movable_Entity
    def move_to(position, criteria=nil)
      self.class.move(self, position, criteria)
    end
  end

end # module
end # module
