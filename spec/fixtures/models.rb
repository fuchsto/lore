
require 'rubygems'
require('lore')
require('lore/model')

module Lore
module Spec_Fixtures
module Models

  NAME_FORMAT = { :format => /^([a-zA-Z_0-9])+$/, :length => 3..100, :mandatory => true }

  class Manufacturer < Lore::Model
    table :manufacturer, :public
    primary_key :manuf_id, :manuf_id_seq

    validates :name, NAME_FORMAT

    use_label :name
  end

  class Owner < Lore::Model
    table :owner, :public
    primary_key :owner_id, :owner_id_seq

    validates :name, NAME_FORMAT
  end

  class Vehicle < Lore::Model
    table :vehicle, :public
    primary_key :id, :vehicle_id_seq

    has_a Manufacturer, :manuf_id
    has_n Owner, :vehicle_id

    validates :maxspeed, :mandatory => true
    validates :num_seats, :mandatory => true
    validates :name, NAME_FORMAT

    add_input_filter(:name) { |name|
      name.gsub(/[^a-zA-Z_0-9]/,'').downcase
    }
    add_input_filter(:maxspeed) { |m| m.to_s.sub('km/h','') }
    add_output_filter(:maxspeed) { |m| m << 'km/h' }

  # add_select_filter { |clause| clause & (Vehicle.deleted == 't') }
  end

  class Vehicle_Owner < Lore::Model
    table :vehicle_owner, :public
    primary_key :vehicle_id
    primary_key :owner_id
    #    aggregates Vehicle, :vehicle_id
    #    aggregates Owner, :owner_id
    # maps Vehicle, Owner
    
    def get_owner()
      Owner.find(1).with(Owner.owner_id == owner_id).entity
    end
  end

  class Car_Type < Lore::Model
    table :car_type, :public
    primary_key :car_type_id, :car_type_id_seq

    validates :type_name, NAME_FORMAT

    use_label :type_name
  end

  class Motor < Lore::Model
    table :motor, :public
    primary_key :id, :motor_id_seq
    
    expects :kw
  end

  class Motorized_Vehicle < Vehicle
    table :motorized, :public
    primary_key :id, :motorized_id_seq

    is_a Vehicle, :vehicle_id
    aggregates Motor, :motor_id
  end

  class Car < Motorized_Vehicle
    table :car, :public
    primary_key :id, :car_id_seq
    
    # This is not a typo: As vehicle_id is a unique, 
    # inherited primary key in Motorized_Vehicle, it 
    # must be allowed for referencing a Motorized_Vehicle. 
    # is_a Motorized_Vehicle, :vehicle_id 
    is_a Motorized_Vehicle, :motorized_id 
    aggregates Car_Type, :car_type_id

    validates :num_doors, :mandatory => true

    add_input_filter(:maxspeed) { |m| m.to_s.gsub('km/h','') }
    add_output_filter(:maxspeed) { |m| m << 'km/h' }

    def drive
      "driving with #{maxspeed}!"
    end
  end

  class Car_Features < Lore::Model
    table :car_features, :public
    primary_key :id, :car_features_id_seq

    has_a Car, :car_id

    expects :color
  end

  class Trailer < Lore::Model
    table :trailer, :public
    primary_key :trailer_id, :trailer_id_seq

    aggregates Car, :car_id
  end

  class Motorbike < Motorized_Vehicle
    table :motorbike, :public
    primary_key :id, :bike_id_seq
    
    is_a Motorized_Vehicle, :vehicle_id
  end

  class Garage < Lore::Model
    table :garage, :public
    primary_key :garage_id, :garage_id_seq
    primary_key :vehicle_id

    has_n Vehicle, :vehicle_id
  end

  class Robot < Lore::Model
    table :robot, :public
    primary_key :id, :robot_id_seq

    def transform
      'Autobot transformed!'
    end
  end

  class Autobot < Robot
    table :autobot, :public
    primary_key :id, :autobot_id_seq

    is_a Robot, :robot_id
    is_a Car, :car_id
  end

  class Sports_Car < Car
    table :sports_car, :public
    primary_key :car_id, Car.id

    is_a Car, :car_id
  end

  class Convertible < Sports_Car
    table :convertible, :public
    primary_key :car_id, Car.id

    is_a Sports_Car, :car_id
  end

end
end
end


