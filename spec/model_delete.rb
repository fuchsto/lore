
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

  it "allows a DSL syntax for deletion without explicitly using a clause object" do

    query = Car.delete { 
      where(:num_seats >= 100)
      limit(4)
    }
    expected = "DELETE FROM public.car
                JOIN public.car_type ON (public.car_type.car_type_id = public.car.car_type_id)
                JOIN public.motorized ON (public.motorized.id = public.car.motorized_id)
                JOIN public.vehicle ON (public.vehicle.id = public.motorized.vehicle_id)
                JOIN public.motor ON (public.motor.id = public.motorized.motor_id)
                WHERE num_seats >= '100' LIMIT 4 OFFSET 0"
    query.sql.gsub(/\s/,'').should == expected.gsub(/\s/,'')
    
  end


end

