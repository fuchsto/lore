
require 'rubygems'
require 'lore'
require 'lore/model'

Lore.logfile = STDOUT
Lore.enable_query_log
Lore.logger.level = Logger::ERROR
Lore.add_login_data 'test' => [ 'cuba', 'cuba23' ]
Lore::Context.enter :test

require './fixtures/models'
require './spec_helpers'

include Lore::Spec_Fixtures::Models

describe(Lore::Table_Accessor) do
  before do
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

  it "allows setting entities for has_a relations" do
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

end
