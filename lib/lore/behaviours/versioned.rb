
module Lore
module Behaviours

  # Usage: 
  #
  #   class My_Model < Lore::Model
  #   extend Lore::Behaviours::Versioned
  #     # ...
  #     version_by :version_number
  #   end
  #
  #   my_model_entity.foo = 'bar'
  #   my_model_entity.commit  # Will create a new version
  #
  module Versioned
  
    # Defines attribute the version number is stored in. 
    # Default is 'version'. 
    def version_by(attrib=:version)
      @version_attr = attrib
      @version_attr_name = attrib.to_s.split('.')[-1].intern
    end
    
    # Overloads commit so it increments the version attribute 
    # before saving instance to database and creates a new 
    # entity with incremented version instead. 
    def commit()
      set_attribute_value(@version_attr, self.attr[@version_attr].to_i + 1)
      create(self.attr)
    end

  end # module

end # module
end # module
