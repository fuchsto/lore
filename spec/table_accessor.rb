
require 'rubygems'
require 'lore'
require 'lore/model'
require './fixtures/blank_models'

NAME_FORMAT = { :format => /^([a-zA-Z_0-9])+$/, :length => 3..100, :mandatory => true }

include Lore::Spec_Fixtures::Blank_Models

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

  it "inherits attribute fields from joined base models" do
    [ 'public.vehicle', 'public.car' ].each { |t| 
      Car.get_fields.keys.include?(t).should == true
    }
    Car.get_fields.keys.length.should == 2

    [ :id, :manuf_id, :num_seats, :maxspeed, :name, :owner_id ].each { |a| 
      Car.get_fields['public.vehicle'].include?(a).should == true
    }
    Car.get_fields['public.vehicle'].length.should == 6

    [ :id, :vehicle_id, :car_type_id, :num_doors ].each { |a| 
      Car.get_fields['public.car'].include?(a).should == true
    }
    Car.get_fields['public.car'].length.should == 4

    # :id is Car.id, as Vehicle.id is shadowed and accessible via :vehicle_id
    [ :id, :vehicle_id, :car_type_id, :num_doors, :manuf_id, :num_seats, :maxspeed, :name, :owner_id ].each { |a| 
      Car.get_fields_flat.include?(a).should == true
    }
    Car.get_fields_flat.length.should == 9
  end

  it "has one or more primary key attributes" do
    Vehicle.primary_key :id, :vehicle_id_seq
    Car.primary_key :id, :car_id_seq
    Motorbike.primary_key :motorbike_id, :motorbike_id_seq
    Owner.primary_key :owner_id, :owner_id_seq
    Car_Type.primary_key :car_type_id, :car_type_id_seq
    Garage.primary_key :garage_id, :garage_id_seq
    Motor.primary_key :id, :motor_id_seq
  end

  it "may have required attributes" do
    Car.expects :num_seats
    # does the same
    Car.validates :num_doors, :mandatory => true
  end

  it "allows adding other models as aggregates" do
    Car.aggregates Car_Type, :car_type_id
    Motorized_Vehicle.aggregates Motor, :motor_id
    Motorized_Vehicle.base_klasses.should_not.include? Motor
    Motorized_Vehicle.aggregate_klasses.should.include? Motor
    Motorized_Vehicle.joined_klasses.should == [ Vehicle, Motor ]
  end

  it "can be derived from one base model or more" do
    Car.is_a Vehicle, :vehicle_id
    Motorbike.is_a Vehicle, :vehicle_id

    Car.create(:name         => 'vehicle name', 
               :num_doors    => 3, 
               :num_seats    => 2, 
               :car_type_id  => Car_Type.create(:name => 'Roadkill X1000').car_type_id, 
               :maxspeed     => 180)
    Car.name.should == 'vehicle name'
    Car.num_doors.should == 5
    Car.maxspeed.should == 120
  end

  it "may have composed primary keys" do
    Vehicle_Owner.primary_key :vehicle_id
    Vehicle_Owner.primary_key :owner_id
  end

  it "allows arbitrary naming of keys" do
    Vehicle.has_a Owner, :owner
  end

  it "provides input and output filters for attribute values" do
  end

  it "does not create records for aggregated models on create procedures" do
    motor   = Motor.create(:motor_name => 'Gaso-Suck 3000', :kw => 200)
    vehicle = Motorized_Vehicle.create(:name => 'vehicle name', 
                                       :num_doors => 3, 
                                       :motor_id => motor.pkey)
    
    vehicle.motor_name.should == 'Gaso-Suck 3000'
    vehicle.kw.should == 200
  end

  it "does not delete records for aggregated models on delete procedures" do
    vehicle  = Motorized_Vehicle.find(1).entity  # Any will do
    motor_id = vehicle.motor.motor_id
    motor    = Motor.get(motor_id) # Re-Select to be sure
    vehicle.delete!
    test     = Motor.get(motor_id) # Re-Select to be sure
    test.should_not == false
  end

  it "defines attributes that cannot be set manually as explicit" do
    Car.__attributes__.explicit.should == [ :name, :num_doors, :maxspeed ]
  end

  it "defines all attributes that are not explicit as implicit" do
    Car.__attributes__.implicit.should == { 'public.vehicle' => [ :vehicle_id ], 
                                            'public.car' => [ :car_id ] }
  end

  it "automatically distributes attribute values on base tables on create procedures" do
  # Car.create(:name      => 'vehicle name', 
  #            :num_doors => 5, 
  #            :maxspeed  => 180)
  # Car.name.should == 'vehicle name'
  # Car.num_doors.should == 5
  # Car.maxspeed.should == 120
  end

  it "provides a before_create hook" do
  end

  it "provides an after_create hook" do
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
