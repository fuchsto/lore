
require('lore/validation/type_validator')
require('lore/exceptions/invalid_field')
require('lore/exceptions/validation_failure')
require('lore/exceptions/unknown_type')

module Lore
module Validation
  
  class Parameter_Validator 

    PG_BOOL                 = 16
    PG_SMALLINT             = 21
    PG_INT                  = 23
    PG_TEXT                 = 25
    PG_VARCHAR              = 1043
    PG_TIMESTAMP_TIMEZONE   = 1184

    @logger = Lore.logger
    
    #############################################################
    # To be used inside Table_Accessor with
    # Validator.invalid_params(this, @attribute_values)
    # or e.g. in a dispatcher with
    # Validator.invalid_params(Some_Klass, parameter_hash)
    # 
    def self.validate(klass, value_hash)
    
      Lore.logger.debug { "Validating attributes for #{klass.to_s}: " }
      Lore.logger.debug { "#{value_hash.inspect}" }
      invalid_params     = Hash.new
      attribute_settings = klass.__attributes__
      constraints        = attribute_settings.constraints
      required           = attribute_settings.required

      attribute_settings.types.each_pair { |table, fields|
        begin
          validate_types(fields, value_hash[table], required[table])
        rescue Lore::Exceptions::Invalid_Types => ip
          invalid_params[table] = ip
        end
      }
      
      attribute_settings.constraints.each_pair { |table, fields|
        begin
          validate_constraints(fields, value_hash[table])
        rescue Lore::Exceptions::Unmet_Constraints => ip
          invalid_params[table] = ip
        end
      }
      if invalid_params.length == 0 then return true end
        
      raise Lore::Exceptions::Validation_Failure.new(klass, invalid_params)

    end

    def self.validate_update(klass, value_hash)
      Lore.logger.debug { "Validating attributes for updating #{klass.to_s}: " }
      Lore.logger.debug { "#{value_hash.inspect}" }
      invalid_params     = Hash.new
      attribute_settings = klass.__attributes__
      constraints        = attribute_settings.constraints
      required           = attribute_settings.required

      value_hash.each_pair { |table, attributes|
        types = attribute_settings.types[table] 
        if !types then 
          raise ::Exception.new("No types given for #{klass.to_s} (#{table})")
        end
        types.delete_if { |attribute,value| !attributes[attribute] }
        begin
          validate_types(types, attributes, required[table])
        rescue Lore::Exceptions::Invalid_Types => ip
          invalid_params[table] = ip
        end
      }
      
      value_hash.each_pair { |table, attributes|
        constraints = attribute_settings.constraints[table]
        if constraints then 
          constraints.delete_if { |attribute,constraint| !attributes[attribute] }
          begin
            validate_constraints(constraints, attributes)
          rescue Lore::Exceptions::Unmet_Constraints => ip
            invalid_params[table] = ip
          end
        else 
          Lore.logger.info { "No constraints for #{klass.to_s}?" }
        end
      }
      if invalid_params.length == 0 then return true end
        
      raise Lore::Exceptions::Validation_Failure.new(klass, invalid_params)

    end

    def self.validate_types(type_codes, table_value_hash, required)
      invalid_types  = {} 
      value          = false
      type_validator = Type_Validator.new()

      # DERRN-DERRN-DERRN!! What if there is no value hash? 
      type_codes.each_pair { |field,type|
        field = field.to_sym
        is_required = (required && required[field]) || false

        value = table_value_hash[field] if table_value_hash
        # Replace whitespaces and array delimiters to check for real value length
        value_nil = (value.nil? || value.to_s.gsub(/\s/,'').gsub(/[{}]/,'').length == 0)
        # Is value missing? 
        if (is_required && value_nil) then 
          invalid_types[field] = :missing
          Lore.logger.debug { "Field #{field} is :missing" }
        # Otherwise: Is value of valid type? 
        elsif !value_nil && !type_validator.typecheck(type, value, is_required) then
          invalid_types[field] = type
          Lore.logger.debug { 
            "Field #{field} has invalid type: " << 
            "expected: #{type}, value: #{value}" 
          }
        end
        
      }
      if invalid_types.keys.length > 0 then
        raise Lore::Exceptions::Invalid_Types.new(invalid_types)
      end
      return true
    end

    def self.validate_constraints(table_constraints, table_value_hash)
      unmet_constraints = {}
      table_constraints.each_pair { |attrib, rules|
        value = table_value_hash[attrib.to_sym] if table_value_hash
        rules.each_pair { |rule, rule_value|
          Lore.logger.debug { "Found constraint for #{attrib}: #{rule.inspect} " }
          Lore.logger.debug { "constraint is: #{rule_value.inspect} " }
          if rule == :minlength && value.to_s.length < rule_value then
            unmet_constraints[attrib] = :minlength
            Lore.logger.debug { "Field #{attrib} failed :minlength" }
          end
          if rule == :maxlength && value.to_s.length > rule_value then
            unmet_constraints[attrib] = :maxlength
            Lore.logger.debug { "Field #{attrib} failed :maxlength" }
          end
          if rule == :format && rule_value.match(value.to_s).nil? then
            unmet_constraints[attrib] = :format
            Lore.logger.debug { "Field #{attrib} failed :format - value: #{value.inspect} - match returned #{rule_value.match(value).inspect}" }
          end
        }
      }
      if unmet_constraints.length > 0 then
        raise Lore::Exceptions::Unmet_Constraints.new(unmet_constraints)
      end
      return true
    end

  end

end # module
end # module
