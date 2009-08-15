
require 'rubygems'
require 'lore'
require 'lore/model'
require './spec/fixtures/blank_models'

NAME_FORMAT = { :format => /^([a-zA-Z_0-9])+$/, :length => 3..100, :mandatory => true }

include Lore::Spec_Fixtures::Blank_Models

describe(Lore::Table_Accessor) do
  before do
    Lore::Context.enter :test
    Lore.add_login_data 'test' => [ 'cuba', 'cuba23' ]
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
    Vehicle.fields.should == [ :vehicle_id ] 
  end

  it "has one or more primary key attributes" do
    Vehicle.primary_key :vehicle_id, :vehicle_id_seq
    Car.primary_key :car_id, :car_id_seq
    Motorbike.primary_key :motorbike_id, :motorbike_id_seq
    Owner.primary_key :owner_id, :owner_id_seq
    Car_Type.primary_key :car_type_id, :car_type_id_seq
    Garage.primary_key :garage_id, :garage_id_seq
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

  it "can be derived from one base model or more" do
    Car.is_a Vehicle, :vehicle_id
    Motorbike.is_a Vehicle, :vehicle_id
  end

  it "allows adding other models as aggregates" do
    Motorized_Vehicle.aggregates Motor, :motor_id
    Motorized_Vehicle.base_klasses.should_not.include? Motor
    Motorized_Vehicle.aggregate_klasses.should.include? Motor
    Motorized_Vehicle.joined_klasses.should == [ Vehicle, Motor ]
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
    Car.explicit_attributes.should == [ :name, :num_doors, :maxspeed ]
  end

  it "defines all attributes that are not explicit as implicit" do
    Car.implicit_attributes.should == { 'public.vehicle' => [ :vehicle_id ], 
                                        'public.car' => [ :car_id ] }
  end

  it "automatically distributes attribute values on base tables on create procedures" do
    Car.create(:name      => 'vehicle name', 
               :num_doors => 5, 
               :maxspeed  => 180)
    Car.name.should == 'vehicle name'
    Car.num_doors.should == 5
    Car.maxspeed.should == 120
  end

  it "may have required attributes" do
  end

  it "inherits attribute fields from joined base models" do
    Car.fields.should == [ :car_id ]
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
