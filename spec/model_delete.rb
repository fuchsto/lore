
require 'spec_env'
include Lore::Spec_Fixtures::Models

include Spec_Model_Select_Helpers

describe(Lore::Table_Accessor) do

  it "does not delete records for aggregated models on delete procedures" do
    manuf       = Manufacturer.create(:name => 'Major Motors')
    vehicle     = Car.create(car_create_values(:name => 'wombat', :manuf_id => manuf.pkey))
    manuf_id    = vehicle.manufacturer.manuf_id
    motor_id    = vehicle.motor_id
    manuf       = Manufacturer.get(manuf_id) 
    vehicle.motor_name.should == 'Mock Motor'
    vehicle.delete!
    manuf       = Manufacturer.get(manuf_id) # Re-Select 
    motor       = Motor.get(motor_id)        # Re-Select 
    manuf.should_not == false
    motor.should_not == false
  end

  it "deletes single Model instances on Model#delete" do
    car = Car.create(car_create_values(:name => 'delete_me!'))
    car_id = car.pkey
    car.delete
    Car.get(car_id).should == false
  end

end

