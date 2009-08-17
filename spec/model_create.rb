
require 'spec_env'
include Lore::Spec_Fixtures::Models

describe(Lore::Table_Accessor) do
  before do
  end

  it "does not create records for aggregated models on create procedures" do
    motor   = Motor.create(:motor_name => 'Gaso-Suck 3000', :kw => 200)

    vehicle = Motorized_Vehicle.create(:name => 'vehicle_name', 
                                       :num_doors => 3, 
                                       :num_seats => 5, 
                                       :owner_id  => 0, 
                                       :maxspeed  => 170,
                                       :motor_id => motor.pkey)
    
    vehicle.name.should == 'vehicle_name'
    vehicle.motor_name.should == 'Gaso-Suck 3000'
    vehicle.kw.should == 200
    vehicle.maxspeed.should == "170km/h"
  end

  it "automatically distributes attribute values on base tables on create procedures" do

    motor   = Motor.create(:motor_name => 'Lawn Mower Ultra', :kw => 20)

    car = Car.create(:name        => 'vehicle_name', 
                     :num_doors   => 5, 
                     :num_seats   => 4, 
                     :owner_id    => 0, 
                     :motor_id    => motor.pkey, 
                     :car_type_id => Car_Type.create(:type_name => 'Roadkill X1000').car_type_id, 
                     :maxspeed    => 180)
    car.num_doors.should == 5
    car.name.should == 'vehicle_name'
    car.maxspeed.should == '180km/h'
  end

  it "provides a before_create hook" do
  end

  it "provides an after_create hook" do
  end

end
