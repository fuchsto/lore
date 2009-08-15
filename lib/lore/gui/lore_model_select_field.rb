
require('aurita-gui/form/select_field')

module Aurita
module GUI

  class Lore_Model_Select_Field < Select_Field

    def initialize(model, params, &block)
      @model        = model
      @filter       = params[:filter]
      @filter     ||= true
      @data_type    = Lore::PG_INT
      if block_given? then
        @select_block = block
      else
        @select_block = Proc.new { |clause| clause.where(@filter) }
      end
      params.delete(:filter)
      super(params)
    end

    def option_elements
      elements = []
      options  = []

      foreign_table = @model.table_name
      selectables = @model.select(&@select_block)
      selectables.each { |foreign| 
        foreign_label = ''
        if @model.get_labels.nil? then
          raise Aurita::GUI::Form_Error.new('Specify a label for has_a - related model klasses (here: ' << @model.to_s + ') via "use_label".')
        end
        @model.get_labels.each { |label_attrib|
          foreign_label << foreign.get_attribute_values[foreign_table][label_attrib.split('.')[-1]].to_s << ' '
        }

        @model.get_primary_keys[foreign_table].uniq.each { |keys|
          key_string = ''
          keys.each { |key|
            # concatenate combined primary keys like 'id--id2' -> '3--4'
            if key_string != '' then key_string << '--' end
            key_string << foreign.get_attribute_values[foreign_table][key]
          }
          options << { key_string => foreign_label }
        }
      }
      
      options.each { |map| 
        map.each_pair { |k,v|
          elements << HTML.option(:value => k) { v }
        }
      }
      elements
    end

  end # class

end
end
