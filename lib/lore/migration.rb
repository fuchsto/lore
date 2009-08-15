
require('lore/types')
require('lore/model_factory')

module Lore


  # Usage: 
  # 
  #  class User_Profile_Migration < Lore::Migration
  #
  #    def up
  #      create_table(:user_profile) { 
  #        schema :public
  #        primary_key :user_profile_id, :user_profile_id_seq
  #        index :user_name
  #
  #        user_name Lore::Type.varchar(50), :null => false, :unique => true
  #        is_admin Lore::Type.boolean, :null => false, :default => false
  #        registered Lore::Type.timestamp, :null => false, :default => 'now()'
  #      }
  #    end
  #
  #    def down
  #      drop_table(:user_profile)
  #      drop_sequence(:user_profile_id_seq)
  #    end
  #
  #  end
  #
  #
  class Migration

    attr_reader :primary_keys, :schema, :table, :fields, :field_params, :indices, :drop_tables

    def initialize()
      @primary_keys   = []
      @sequences      = {}
      @fields         = []
      @field_params   = {}
      @indices        = []
      @drop_tables    = []
      @drop_sequences = []
      @constraints    = []
    end

    def create_table(table_name, schema=:public, &block)
      instance_eval(&block)
      @table = table_name
      factory = Model_Factory.new(table_name)
      @primary_keys.each { |p|
        factory.add_attribute(p, :null => false, :type => Lore::Type.integer)
        factory.add_primary_key(:attribute => p, 
                                :key_name => "#{table_name}_pkey", 
                                :sequence => @sequences[p] )
      }
      @fields.each { |f|
        factory.add_attribute(f, @field_params[f])
      }
      factory.build_table
    end

    def drop_table(table_name)
      @drop_tables << table_name
    end
    def drop_sequence(sequence_name)
      @drop_sequences << sequence_name
    end

    def up()
    end

    def down()
    end
      
    def primary_key(key_name, sequence_name=nil)
      key_name = key_name.to_sym
      @primary_keys << key_name
      @sequences[key_name] = sequence_name.to_sym if sequence_name
    end

    def schema(schema_name)
      @schema = schema_name
    end

    def add_field(field_name, type, params={})
      @fields << field_name
      @field_params[field_name] = params
      @field_params[field_name][:type] = type
    end

    def add_constraint(constraint)
      @constraints << constraint
    end

    def index(field_name)
      @indices << field_name
    end

    def method_missing(field_name, type, params={})
      add_field(field_name, type, params)
    end

  end

end

