
require 'spec_env'
include Lore::Spec_Fixtures::Models

describe(Lore::Table_Accessor) do

  before do
    flush_test_data()
  end

  it "provides single inheritance" do
    Motorized_Vehicle.is_a?(Vehicle).should == true
    Car.is_a?(Vehicle).should == true
    
  end

  it "provides multiple inheritance" do 
    Autobot.is_a?(Car).should == true
    Autobot.is_a?(Robot).should == true

    motor = Motor.create(:motor_name => 'Autobot Car Motor', 
                         :kw => 239)
    car_type = Car_Type.create(:type_name => 'Autobot Car')
    
    t = Autobot.create(# Attributes for Vehicle
                       :name => 'Autobot', 
                       :num_seats => 4, 
                       :maxspeed => 190, 
                       :owner_id => 23, 
                       :manuf_id => 42, 
                       # Attributes for Motorized
                       :motor_type => 'brushless', 
                       :motor_id => motor.pkey, 
                       # Attributes for Car
                       :car_type_id => car_type.pkey, 
                       :num_doors => 5, 
                       # Attributes for Robot
                       :robot_class => 'Exoskel X3000',
                       :locomotion_type => 'bipedal')
    
    t.name.should == 'autobot'
    t.num_seats.should == 4
    t.manuf_id.should == 42
    t.motor_type.should == 'brushless'
    t.locomotion_type.should == 'bipedal'
    
    t.transform.should == 'Autobot transformed!'
  end

end
