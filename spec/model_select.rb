
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

  it "provides convenience methods for selects" do
    car_org = Car.create(car_create_values(:name => "The Car" ))
    car_sel = Car.find(1).with(Car.name == "thecar").entity
    car_org.name.should == "thecar"
    car_sel.name.should == "thecar"
    car_org.should == car_sel
  end

  it "allows arbitrary joins with other models" do
    
    cf = Car_Features.create(:car_id => Car.create(car_create_values(:name => 'fordmondeo')).pkey, 
                             :color  => 'red')

    res = Car.select { |c|
      c.join(Car_Features).on(Car.id == Car_Features.car_id) { |cc|
        cc.where(Car.name.ilike('ford%'))
      }
    }.first
    res.color.should == 'red'
    res.name.should == 'fordmondeo'

  end

  it "allows selecting skalar values, e.g. for aggregate functions" do
    most_recent_car = false
    3.times { 
      most_recent_car = Car.create(car_create_values(:name => "The Car" ))
    }
    values = Car.select_values('count(*), max(car.id)') { |c|
      c.where(true)
    }.first

    values[0].to_i.should == 3
    values[1].to_i.should == most_recent_car.id
  end

  it "provides convenience methods for selecting skalar values" do

    most_recent_car = false
    id_sum = 0
    3.times { 
      most_recent_car = Car.create(car_create_values(:name => "The Car" ))
      id_sum += most_recent_car.id
    }
    Car.value_of.max(Car.id).to_i.should == most_recent_car.id
    Car.value_of.sum(Car.id).to_i.should == id_sum

  end

end


