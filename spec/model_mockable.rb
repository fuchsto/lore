
require 'spec_env'
include Lore::Spec_Fixtures::Models

describe(Lore::Table_Accessor) do

  it "allows creating shallow (mocked) instances with no connection to DB" do

    mock = Car.create_shallow(:name        => 'the car', 
                              :num_seats   => 5, 
                              :num_doors   => 4, 
                              :motor_id    => 23, 
                              :maxspeed    => 300, 
                              :car_type_id => 42)
    mock.car_type_id.should == 42
    mock.motor_id.should == 23
    mock.name.should == 'thecar'

  end

end
