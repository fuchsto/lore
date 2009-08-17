
require 'spec_env'
include Lore::Spec_Fixtures::Models

module Spec_Model_Select_Helpers
  OWNER_ID = 12
  MANUF_ID = 23
  MOTOR_ID = 42

  def mock_car_type
    Car_Type.create(:type_name => 'Mock Type').pkey
  end
  def mock_motor
    Motor.create(:motor_name => 'Mock Motor', :kw => 200).pkey
  end

  def car_create_values(replacements={})
    { 
      :name        => 'Some Car', 
      :maxspeed    => 123, 
      :num_doors   => 5, 
      :num_seats   => 4, 
      :owner_id    => OWNER_ID, 
      :manuf_id    => MANUF_ID, 
      :motor_id    => mock_motor(), 
      :car_type_id => mock_car_type()
    }.update(replacements)
  end
end
include Spec_Model_Select_Helpers

describe(Lore::Table_Accessor) do
  before do
    flush_test_data()
  end

  it "should provide a DSL for selects" do 

    for index in 0...3 do 
      Car.create(car_create_values(:name => "Car #{index}" ))
    end

    expected = Car.select_value('count(*)') { |c| c.where(true) }
    expected.to_i.should == 3

    car = Car.select { |c|
      c.where((c.name == "car1").or(c.name == "car2"))
      c.limit(1)
    }.first
    car.name.should == "car1"

    car = Car.select { |c|
      c.where((c.name == "car1").or(c.name == "car2"))
      c.limit(1, 1)
    }.first
    car.name.should == "car2"
  end

  it "should provide convenience methods for selects" do
    car_org = Car.create(car_create_values(:name => "The Car" ))
    car_sel = Car.find(1).with(Car.name == "thecar").entity
    car_org.name.should == "thecar"
    car_sel.name.should == "thecar"
    car_org.should == car_sel
  end

end


