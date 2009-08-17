
require 'spec_env'
include Lore::Spec_Fixtures::Models

describe(Lore::Table_Accessor) do
  before do
    flush_test_data()
  end

  it "is assigned to a base table" do
    Car.table_name.should == 'public.car'
    Vehicle.table_name.should == 'public.vehicle'
  end

  it "loads attribute fields automatically as array of symbols" do
    owner = Owner.create(:name => 'Filou')
    manuf_org = Manufacturer.create(:name => 'Ford')
    manuf_new = Manufacturer.create(:name => 'Ford')
    v = Vehicle.create(:name => 'Ford Mondeo', 
                       :num_seats => 100, 
                       :maxspeed => 180, 
                       :manuf_id => manuf_org.pkey, 
                       :owner_id => owner.pkey)
    v.manufacturer.should == manuf_org
  end

  it "allows setting entities for 1:1 relations" do
    owner     = Owner.create(:name => 'Filou')
    manuf_org = Manufacturer.create(:name => 'Ford')
    manuf_new = Manufacturer.create(:name => 'Ford')
    motor     = Motor.create(:motor_name => 'Ford V8', :kw => 120)
    type      = Car_Type.create(:type_name => 'Limousine')
    v = Car.create(:name => 'Ford Mondeo', 
                   :motor_id => motor.pkey,
                   :num_doors => 3, 
                   :num_seats => 100, 
                   :maxspeed => 180, 
                   :car_type_id => type.pkey, 
                   :manuf_id => manuf_org.pkey, 
                   :owner_id => owner.pkey)
    v.manufacturer.should == manuf_org
    v.manufacturer = manuf_new
    
    expected = { 'public.vehicle'   => { :id => v.vehicle_id }, 
                 'public.car'       => { :id => v.id }, 
                 'public.motorized' => { :id => v.motorized_id } } 
  
    v.get_primary_key_value_map.should_be expected
    v.commit
    v.manufacturer.should == manuf_new
    
    v.set_manufacturer!(manuf_org)
    v.manufacturer.should == manuf_org
  end

  it "provides 1:n associations" do
    garage = Garage.create()
    vehicle_1 = Vehicle.create()
    vehicle_2 = Vehicle.create()
    car_1 = Car.create()
    car_2 = Car.create()

    garage.add_vehicle(vehicle_1)
    garage.add_vehicle(car_1)
    garage.save
    expected = [ vehicle_1, car_1 ]
    garage.vehicle_set.should_be expected

    garage.vehicle_set = [ vehicle_2, car_2 ]
    garage.save
    expected = [ vehicle_2, car_2 ]
    garage.vehicle_set.should_be expected

    garage.vehicle_set.delete(car2)
    garage.save
    expected = [ vehicle_2 ]
    garage.vehicle_set.should_be expected
  end

  it "provides n:n associations" do
    
  end

end
