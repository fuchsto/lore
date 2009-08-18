
require('logger')

require('lore/model/aspect');
require('lore/model/table_accessor');

module Lore

  # For API details see Lore::Table_Accessor
  #
  #
  # =How to define models
  #
  # Example: 
  #
  #   require 'lore/model'
  #
  #   class Vehicle < Lore::Model
  #   end
  #
  #   class Car < Vehicle
  #   end
  #
  # Sets following defaults: 
  #  
  #   class Vehicle
  #     table :vehicle, :vehicle_id
  #     primary_key :id              # or :vehicle_id if :id is not present
  #   end
  #
  #   class Car < Vehicle
  #     table :car, :public
  #     primary_key :id              # or :car_id if :id is not present
  #     is_a Vehicle, :vehicle_id 
  #   end
  #
  # = How to use models
  # 
  # == Creating entities (INSERTs)
  #   
  #   manuf_1 = Manufacturer.create(:name => 'Audi')
  #   manuf_2 = Manufacturer.create(:name => 'BMW')
  #   car     = Car.create(:manufacturer => manuf, :name => 'TT')
  #
  # == Changing entities (UPDATEs)
  #
  #   car['name'] = 'BMW318i'
  #   car.manufacturer = manuf_2  # same as car[:manufacturer_id] = manuf_2.manufacturer_id
  #   car.commit
  #
  # == Deleting entities (DELETEs)
  #
  #   car.delete!
  # is the same as
  #   Car.delete.where(Car.car_id == car.car_id).perform
  # is the same as
  #   Lore.perform Car.delete.where(Car.car_id == car.car_id) 
  # is the same as
  #   Car.delete { |c|
  #     c.where(c.car_id = car.car_id)
  #   }
  #
  # =How to disable/enable features
  #
  # Lore::Model extends 
  # * Lore::Cache::Cacheable
  # * Lore::Query_Shortcuts
  # * Lore::Aspect
  # 
  # Each of them is optional. If you want, for example, a minimalistic 
  # version of Lore::Model with comfortable query interfaces you can define 
  # your own Model class that extends the Lore::Query_Shortcuts module only: 
  #
  #   class Slim_Model < Lore::Table_Accessor
  #     extend Lore::Query_Shortcuts
  #   end
  #
  # You can use it as base class for other Model classes, too: 
  #
  #   class Cache_Model < Slim_Model
  #     extend Lore::Query_Shortcuts
  #     extend Lore::Cacheable
  #   end
  #
  # You also can define this differently for every model by deriving them
  # from Lore::Table_Accessor and extending every single one of them: 
  #
  #   class User < Lore::Table_Accessor
  #   extend Lore::Query_Shortcuts
  #   extend Lore::Aspect
  #     
  #     table :user, :public
  #     primary_key :user_id
  #     
  #   end
  #
  # =How to use Lore::Model in a Rails app
  #
  # By default, Lore::Model doesn't extend Rails interface bridges. You 
  # either can define your own Model base class (see: How to disable/enable 
  # features) and extend it by Lore::Rails::Model
  #
  #   class My_Model < Lore::Model
  #     extend Lore::Rails::Model
  #   end
  #
  # ... or extend Lore::Model directly: 
  #
  #   Lore::Model.extend Lore::Rails_Bridge
  #
  # In this case, every Model in your app will include Rails interfaces. 
  #
  class Model < Table_Accessor
    extend Lore::Cache::Cacheable
    extend Lore::Query_Shortcuts
    extend Lore::Aspect
  # extend Lore::Migration

    def by_id(pkey_id)
      _by_id(pkey_id).first # Auto-defined in Lore::Table_Accessor.primary_key
    end
  end

end
