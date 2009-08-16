
require 'rubygems'
require 'lore'
require 'lore/model'
require './fixtures/blank_models'
require './spec_helpers'

NAME_FORMAT = { :format => /^([a-zA-Z_0-9])+$/, :length => 3..100, :mandatory => true }

include Lore::Spec_Fixtures::Blank_Models

Lore.logger.level = Logger::ERROR
Lore::Context.enter :test
Lore.add_login_data 'test' => [ 'cuba', 'cuba23' ]

describe(Lore::Table_Accessor) do
  before do
  # Lore::Spec_Fixtures::Models::Vehicle.delete_all
  # Lore::Spec_Fixtures::Models::Car.delete_all
  # Lore::Spec_Fixtures::Models::Motorbike.delete_all
  # Lore::Spec_Fixtures::Models::Owner.delete_all
  # Lore::Spec_Fixtures::Models::Vehicle_Owner.delete_all
  # Lore::Spec_Fixtures::Models::Car_Type.delete_all
  # Lore::Spec_Fixtures::Models::Garage.delete_all
  # Lore::Spec_Fixtures::Models::Motor.delete_all
  # Lore::Spec_Fixtures::Models::Motorized_Vehicle.delete_all
  end

  it "is assigned to a base table" do
    Vehicle.table :vehicle, :public
    Car.table :car, :public
    Motorbike.table :motorbike, :public
    Owner.table :owner, :public
    Vehicle_Owner.table :vehicle_owner, :public
    Car_Type.table :car_type, :public
    Garage.table :garage, :public
    Motor.table :motor, :public
    Motorized_Vehicle.table :motorized, :public

    Car.table_name.should == 'public.car'
    Vehicle.table_name.should == 'public.vehicle'
    Motorbike.table_name.should == 'public.motorbike'
    Owner.table_name.should == 'public.owner'
    Vehicle_Owner.table_name.should ==  'public.vehicle_owner'
    Car_Type.table_name.should ==  'public.car_type'
    Garage.table_name.should == 'public.garage'
  end

  it "loads attribute fields automatically as array of symbols" do
    Vehicle.get_fields.should == { 'public.vehicle' => [ :id, :manuf_id, :num_seats, :maxspeed, :name, :owner_id ] }
    Vehicle.get_fields_flat.should == [ :id, :manuf_id, :num_seats, :maxspeed, :name, :owner_id ] 
  end

  it "has one or more primary key attributes" do
    Vehicle.primary_key :id, :vehicle_id_seq
    Car.primary_key :id, :car_id_seq
    Motorbike.primary_key :motorbike_id, :motorbike_id_seq
    Owner.primary_key :owner_id, :owner_id_seq
    Car_Type.primary_key :car_type_id, :car_type_id_seq
    Garage.primary_key :garage_id, :garage_id_seq
    Motor.primary_key :id, :motor_id_seq
    Motorized_Vehicle.primary_key :id, :motorized_id_seq
  end

  it "may have required attributes" do
    Car.expects :num_seats
    # does the same
    Car.validates :num_doors, :mandatory => true
  end

  it "allows adding other models as aggregates" do
    Car.aggregates Car_Type, :car_type_id
    Motorized_Vehicle.is_a Vehicle, :vehicle_id
    Motorized_Vehicle.aggregates Motor, :motor_id
    Motorized_Vehicle.__associations__.base_klasses.values.should == [ [ Vehicle, [ :vehicle_id ] ] ]
    Motorized_Vehicle.__associations__.aggregate_klasses.values.should == [ [ Motor , [ :motor_id ] ] ]
    Motorized_Vehicle.__associations__.joined_models.values.should == [ [ Vehicle, [ :vehicle_id ] ] , [ Motor, [ :motor_id ] ] ]
  end

  it "can be derived from one base model or more" do
    Car.is_a Motorized_Vehicle, :vehicle_id
    Motorbike.is_a Vehicle, :vehicle_id

    Car.is_a?(Motorized_Vehicle).should == true
    Car.is_a?(Vehicle).should == true
  end

  it "inherits attribute fields from joined base models" do
    expected_fields = { 
      'public.vehicle'   => [ :id, :manuf_id, :num_seats, :maxspeed, :name, :owner_id ], 
      'public.car_type'  => [ :car_type_id, :type_name ], 
      'public.car'       => [ :id, :vehicle_id, :car_type_id, :num_doors ], 
      'public.motorized' => [ :vehicle_id, :motor_id, :id ], 
      'public.motor'     => [ :id, :motor_name, :kw ]
    }
    Car.get_fields.should_be expected_fields
  end

  it "may have composed primary keys" do
    Vehicle_Owner.primary_key :vehicle_id
    Vehicle_Owner.primary_key :owner_id
  end

  it "may have non-sequential primary keys" do
  end

  it "allows arbitrary naming of keys" do
    Vehicle.has_a Owner, :owner
  end

  it "provides input and output filters for attribute values" do
  end

  it "defines attributes that cannot be set manually as explicit" do
    expected = { 
      # has_a foreign keys :manuf_id and owner are explicit: 
      'public.vehicle' => [ :manuf_id, :num_seats, :maxspeed, :name, :owner_id ], 
      # Aggregate foreign key :motor_id is explicit: 
      'public.motorized' => [ :motor_id ], 
      # Aggregate foreign key :car_type_id is explicit: 
      'public.car' => [ :car_type_id, :num_doors ] 

      # Aggregated models do not extend implicit or explicit fields!
      # 'public.motor' => [ :motor_name ],
      # 'public.car_type' => [ :type_name ],
    }

    Car.__attributes__.explicit.should_be expected
  end

  it "defines all attributes that are not explicit as implicit" do
    expected = { 
      'public.vehicle' => [ :id ], 
      'public.motorized' => [ :id, :vehicle_id ], 
      'public.car' => [ :id, :vehicle_id ] 

      # Aggregated models do not extend implicit or explicit fields!
      # 'public.motor' => [ :id ],
      # 'public.car_type' => [ :car_type_id ],
    }

    Car.__attributes__.implicit.should_be expected
  end

  it "provides a before_select hook" do
  end

  it "provides validating presence of attribute values" do
    Vehicle.validates :name, :mandatory => true
    # .expects does the same
    Car.expects :num_doors
  end

  it "provides validating attribute values by length" do
    Vehicle.validates :name, :maxlength => 20
  end

  it "provides validating attribute values by format" do
    Vehicle.validates :name, :format => NAME_FORMAT
  end


end
