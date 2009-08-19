
def global_eval(string)
  eval(string)
end

module Lore

  class Model_Factory

    attr_accessor :output_folder, :output_file
    attr_reader :model_name, :fields, :primary_keys, :aggregates, :types, :labels

    # Usage: 
    #   builder = Model_Builder.new('new_model')
    #   builder.add_attribute('model_id', :type => Type.integer, :not_null => true)
    #   builder.add_attribute('name', :type => Type.integer, :not_null => true, :check => "name <> ''", :unique => true)
    #   builder.add_attribute('created', :type => Type.timestamp, :not_null => true, :default => 'now()')
    #   builder.add_primary_key(:key_name => 'model_pkey', :attribute => 'model_id')
    #   builder.set_table_space('diskvol1')
    #   builder.build()
    def initialize(model_name, connection=nil)
      name_parts        = model_name.to_s.split('::')
      @model_name       = name_parts[-1]
      @model_name       = @model_name.split('_').map { |p| p.upcase }.join('_')
      @namespaces       = name_parts[0..-2]

      @table_name       = @model_name.downcase

      @output_folder    = './'
      @output_file      = @table_name + '.rb'

      @connection       = connection
      @connection       = Lore::Connection unless @connection
      @table_space      = ''

      @fields           = Array.new
      @types            = Array.new
      @labels           = Array.new
      @aggregates       = Array.new
      @attributes       = Array.new
      @expects          = Array.new
      @constraints      = Array.new
      @schema_name      = :public
      @primary_keys     = Array.new
      @attribute_types  = Hash.new
      @attribute_labels = Hash.new
      
      @base_model_klass = 'Lore::Model'
      @base_model_klass_file = 'lore/model'
    end

    def self.drop_model(model)
      query =  'DROP TABLE ' << model.table_name + ';'
      model.get_sequences()[model.table_name].each { |key, seq|
        query << 'DROP SEQUENCE ' << seq.to_s + ";\n" 
      }
      Lore::Connection.perform(query)
    end
    
    def use_model(model_klass_string, model_klass_file)
      @base_model_klass = model_klass_string
    end

  public

    # Usage: 
    # 
    #  add_attribute('primary_id', 
    #                :type => integer, 
    #                :not_null => true, 
    #                :default => '0', 
    #                :length => 20, 
    #                :check => '...')
    #
    def add_attribute(attrib_name, attrib_hash={})

      @fields << { :name => attrib_name, :type => attrib_hash[:type] }

      attribute_part = ''
      attribute_part << "#{attrib_name} \t #{attrib_hash[:type]}"
      if attrib_hash[:length].instance_of? Integer then
        attribute_part << '(' << attrib_hash[:length].to_s + ')'
      end
      if attrib_hash[:mandatory] || 
         attrib_hash[:null].instance_of?(FalseClass) || 
         attrib_hash[:not_null] then
        add_mandatory(attrib_name)
        attribute_part << ' NOT NULL ' 
      end
      attribute_part << ' UNIQUE ' if attrib_hash[:unique]
      
      @attributes << attribute_part
      @attribute_types[attrib_name]  = attrib_hash[:type]
      @attribute_labels[attrib_name] = attrib_hash[:label]
    end
    def set_attributes(attrib_hash)
      attrib_hash.each_pair { |attrib_name, attrib_props|
        add_attribute(attrib_name.to_s, attrib_props)
      }
    end
    
    def set_table_space(table_space)
      @table_space = table_space
    end

    def add_has_a(model, attribute_name)
      @aggregates << [:has_a, model, attribute_name]
    end

    def add_mandatory(attribute_name)
      @expects << attribute_name.to_s
      @expects.uniq!
    end

    def add_is_a(model, attribute_name)
      @aggregates << [:is_a, model, attribute]
    end

    def add_label(label)
      @labels << label.downcase
    end

    def set_labels(labels)
      @labels = labels
    end

    # Usage: 
    #  add_primary_key(:attribute => 'my_id', :key_name => 'my_model_pkey')
    #
    def add_primary_key(key_hash)
      key_hash[:attribute] = key_hash[:attribute].to_s
      key_hash[:key_name] = key_hash[:key_name].to_s
      sequence = key_hash[:sequence] 
      @primary_keys << [ key_hash[:attribute], sequence, key_hash[:key_name] ]
    end

  public

    # Finally installs model table
    def build_table

      query = ''
      pkey_constraint = "CONSTRAINT #{@table_name}_pkey PRIMARY KEY (#{@primary_keys.collect { |pk| pk[0] }.join(',')})\n"
      @primary_keys.each { |pk|
        query << "CREATE SEQUENCE #{pk[1]}; \n" if pk[1]
      }

      query << 'CREATE TABLE ' << @table_name + " ( \n" 
      query << @attributes.join(", \n")
      query << ', ' << "\n"
      query << pkey_constraint
      query << "\n" << ') ' << @table_space + ';'
      
      @connection.perform(query)
    end
    
    def build_model_klass
      build_table
      model_klass_string = build_model_klass_string
      if @output_file then
        out = @output_folder + @output_file
        prepend_header = !File.exists?(out)
        File.open(out, 'a+') { |f|
          f << "\nrequire('" << @base_model_klass_file + "') \n\n" if prepend_header
          prepend_header = false
          f << model_klass_string
          f << "\n\n"
        }
      end
      global_eval(model_klass_string)
    end

    def build_model_klass_string

      requires = ''
      @aggregates.each { |type, model_name, attribute|
        requires << "require('aurita/main/model/" << model_name.downcase + "')"
        requires << "\n"
      }
      requires << "\n"

      model = requires

      model << '  class ' << @model_name.to_s + ' < ' << @base_model_klass + " \n"
      model << '    table :' << @table_name.to_s
      model << ', :' << @schema_name.to_s
      model << "\n"
      @primary_keys.each { |key|
      model << '    primary_key :' << key[0]
      model << ', :' << key[1] if key[1]
      model << "\n"
      }
      @attribute_types.each_pair { |attrib, type|
      model << ' #  has_attribute :' << attrib + ', Lore::Type.' << type
      model << "\n"
      }

      model << "\n"
      model << "    def self.attribute_labels\n"
      model << "      { \n"
      @attribute_labels.each_pair { |attrib, label|
      model << "        '#{attrib}' => '#{label}',\n"
      }
      model << "        :none => ''\n"
      model << "      } \n"
      model << "    end\n"

      @expects.each { |attrib|
      model << '    expects :' << attrib
      model << "\n"
      }
      
      model << '    use_label :' << @labels.join(', :') if @labels.first
      model << "\n"

      @aggregates.each { |type, model_name, attribute_name|
      model << '    has_a ' << model_name + ', :' << attribute_name.downcase if type==:has_a
      model << '    is_a ' << model_name + ', :' << attribute_name.downcase if type==:is_a
      model << "\n"
      }
      model << "\n" << '  end'
      @namespaces.reverse.each { |ns|
        model = 'module ' << ns + "\n" << model << "\n" << 'end'
        
      }
      return model
    end

  end # class

end # module
