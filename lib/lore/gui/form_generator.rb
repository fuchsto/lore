
require('aurita-gui')
require('lore/gui/lore_model_select_field')

module Lore
module GUI

  # A factory rendering Aurita::GUI:Form instances for 
  # Aurita::Model classes. 
  #
  # Usage: 
  #   
  #   generator = Lore_Form_Generator.new(Some_Lore_Model)
  #   generator.params = { :action => '/aurita/dispatch', :onsubmit => "alert('submitting'); " }
  #   generator.generate
  #   puts generator.form
  #
  class Form_Generator 
    include Aurita::GUI

    attr_reader :form, :klass
    attr_accessor :custom_elements, :labels, :params, :form_class

    def initialize(klass=nil)
      @klass           = klass
      @labels          = {}
      @params          = {}
      @custom_elements = {}
      @form            = false
      @form_class      = Aurita::GUI::Form
    end

    def form
      generate() unless @form
      @form
    end

    @@type_field_map = { 
      :default                    => Proc.new { |l,f| Input_Field.new(:label => l, :name => f) }, 
      Lore::PG_BOOL               => Proc.new { |l,f| Boolean_Field.new(:label => l, :name => f) }, 
      Lore::PG_VARCHAR            => Proc.new { |l,f| Input_Field.new(:label => l, :name => f) }, 
      Lore::PG_SMALLINT           => Proc.new { |l,f| Input_Field.new(:label => l, :name => f) }, 
      Lore::PG_INT                => Proc.new { |l,f| Input_Field.new(:label => l, :name => f) }, 
      Lore::PG_TEXT               => Proc.new { |l,f| Textarea_Field.new(:label => l, :name => f) }, 

      Lore::PG_TIMESTAMP_TIMEZONE => Proc.new { |l,f| Datetime_Field.new(:label => l, :name => f, 
                                                                         :date_format => 'dmy', 
                                                                         :time_format => 'hms', 
                                                                         :year_range => (2009..2020)) }, 

      Lore::PG_TIMESTAMP          => Proc.new { |l,f| Datetime_Field.new(:label => l, :name => f, 
                                                                         :date_format => 'dmy', 
                                                                         :time_format => 'hms', 
                                                                         :year_range => (2009..2020)) },

      Lore::PG_DATE               => Proc.new { |l,f| Date_Field.new(:label => l, :name => f, 
                                                                     :date_format => 'dmy', 
                                                                     :year_range => (2009..2020)) },

      Lore::PG_TIME               => Proc.new { |l,f| Time_Field.new(:label => l, :name => f, 
                                                                     :time_format => 'hm') }
    }

  protected 

    def field_for(type, params)
      element   = @@type_field_map[type]
      element ||= @@type_field_map[:default]
      return element.call(params[:label], params[:name])
    end

  public

    def generate
      @form = @form_class.new(@params)
      model_labels   = @klass.attribute_labels if @klass.respond_to?(:attribute_labels)
      model_labels ||= {}

      @klass.get_attributes.each_pair { |table, attributes|

        attributes.each { |attribute|
          label_tag    = table.gsub('.','--') << '--' << attribute
          label        = @labels[label_tag]
#         label        = model_labels[attribute.to_s] if label.to_s == ''
          label        = attribute.capitalize if label.to_s == ''

          full_attrib  = table + '.' << attribute
          field_name   = full_attrib
          form_element = false
          constraints  = @klass.get_constraints
          constraints  = constraints[table] if constraints
          constraints  = constraints[attribute] if constraints
          
          # @custom_elements is a hash mapping attribute names to
          # Custom_Element instances. 
          if ((@custom_elements[table]) and
              (@custom_elements[table][attribute])) then
            
            form_element = @custom_elements[table][attribute].new(:label => label, 
                                                                  :id => full_attrib, 
                                                                  :name => field_name)
            
          elsif (@klass.get_primary_keys[table].nil? or                      # Ignore primary key attributes
                 !@klass.get_primary_keys[table].include? attribute) and        
                (@klass.get_implicit_attributes[table].nil? or               # Ignore implicit attributes
                 !@klass.get_implicit_attributes[table].include? attribute) and 
                (@klass.get_has_a_klasses.nil? or                            # Ignore attributes aggregated via has_a associations (added later)
                 @klass.get_has_a_klasses[full_attrib].nil?) and        
                (@klass.get_hidden_attributes[table].nil? or                 # Ignore otherwise hidden attributes
                 !@klass.get_hidden_attributes[table].include? attribute)
          then
          # Attribute has to be added to form, according to data type
            form_element = field_for(@klass.get_attribute_types[table][attribute], :name => field_name, :label => label)
          elsif (!@klass.get_has_a_klasses.nil? and
                 !@klass.get_has_a_klasses[full_attrib].nil?)
          then 
            foreign_klass   = @klass.get_has_a_klasses[full_attrib]
            form_element    = Aurita::GUI::Lore_Model_Select_Field.new(foreign_klass, :label => label, :name => field_name)

          elsif (!@klass.get_aggregate_klasses.nil? and
                 !@klass.get_aggregate_klasses[full_attrib].nil?)
          then 
            foreign_klass   = @klass.get_aggregate_klasses[full_attrib]
            form_element    = Aurita::GUI::Lore_Model_Select_Field.new(foreign_klass, :label => label, :name => field_name)
            
          # Attribute is explixit (expected/required) but not 
          # catched before -> Add attribute as hidden field: 
          elsif (!@klass.get_explicit_attributes[table].nil? and 
                 @klass.get_explicit_attributes[table].include? attribute)
          then

          elsif (!@klass.get_implicit_attributes[table].nil? and 
                 @klass.get_implicit_attributes[table].include? attribute)
          then
            # Implicit field, ignored
          end

          if form_element then
            form_element.data_type = @klass.get_attribute_types[table][attribute] 
            if(!@klass.get_explicit_attributes[table].nil? and 
               @klass.get_explicit_attributes[table].include? attribute) then
              form_element.required!
            end
            if constraints then
              if constraints[:minlength] then
              end
              if constraints[:maxlength] then
              end
              if constraints[:format] then
              end
            end
            @form.add(form_element) 
          end
        }
      }
      return @form
    end
    
  end # class

end # module
end # module
