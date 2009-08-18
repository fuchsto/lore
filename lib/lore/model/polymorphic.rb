
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

    # TODO: 
    #
    #  Optimize this to a query like: 
    #
    #    select *, [null] from asset 
    #      join media_asset on (asset.asset_id == media_asset.asset_id)
    #      # custom and implicit joins here
    #    union all 
    #    select * from asset
    #      join document_asset on (asset.asset_id == document_asset.asset_id)
    #      # custom and implicit joins here
    #    # Custom selection params: 
    #    where asset.folder = '/tmp/public/'
    #    order by asset_id
    #  
    #  Note: Prior to this query, the maximal number of result fields has 
    #  to be resolved and each 'select *' has to be padded with 'null' for 
    #  missing fields, as UNION needs the same field number in every 
    #  result row.  
    #
    def select_polymorphic(clause=nil, &block)
      base_entities = select(clause, &block)
      base_entities.map { |e|
        cmodel = e.get_concrete_model
        if cmodel then
          e = cmodel.load(get_fields[table_name].first => e.pkey()) 
        else 
          e = false
        end
        e
      }
    end

    def polymorphic_attribute
      @polymorphic_attribute
    end

  end

  module Polymorphic_Instance_Methods

    def get_concrete_model
      concrete_model_name = self.__send__(self.class.polymorphic_attribute)
      return unless concrete_model_name
      eval(concrete_model_name)
    end

  end

end
