
module Lore

  module Mockable

    # Create a shallow instance, that is: A mock instance with no reference to 
    # DB model. Attribute values passed to Table_Accessor.create_shallow are 
    # not processed through hooks, filters, and validation. 
    # Values are, however, processed through output filters. 
    # Usage and result is 
    # the same as for Table_Accessor.create, but it only returns 
    # an accessor instance, without storing it in the database. 
    # To commit a shallow copy to database (and thus process given attribute 
    # values through stages mentioned before), call #commit. 
    def create_shallow(attrib_values)
      attrib_values[:concrete_model] = self.to_s 
      before_create(attrib_values)

      input_filters = @__filters__.input_filters
      attrib_key  = ''
      attrib_name = ''

      attrib_values.each_pair { |attrib_name, attrib_value|
        if attrib_name.instance_of? Symbol then 
          attrib_key = attrib_name
        else 
          attrib_key = attrib_name.split('.')[-1].to_sym
        end
        
        if (input_filters && input_filters[attrib_key]) then
          attrib_values[attrib_name] = input_filters[attrib_key].call(attrib_value) 
        end
      }
      after_filters(attrib_values)
      
      values = distribute_attrib_values(attrib_values)
      
      before_validation(values)
      if @__associations__.polymorphics then
        Lore.logger.debug { "Polymorphic create on #{self.to_s}" }
        @__associations__.polymorphics.each_pair { |table, model_field|
          values[table][model_field] = self.to_s
        }
      end
      Lore::Validation::Parameter_Validator.validate(self, values)

      return self.new(values)
    end

    # Alias module .self methods
    def self.extended(object)
      class << object
        alias_method :create_mock, :create_shallow unless method_defined? :create_mock
        alias_method :create_shallow, :create_mock
        alias_method :mock, :create_shallow unless method_defined? :mock
        alias_method :create_shallow, :mock
      end
    end

  end

end
