
require 'spec_env'
include Lore::Spec_Fixtures::Models
include Spec_Model_Select_Helpers

describe(Lore::Table_Accessor) do
  before do
    flush_test_data()
  end

  it "proved unions of result rows" do
    10.times { 
      Car.create(car_create_values(:num_seats => 4, :maxspeed => 170))
      Car.create(car_create_values(:num_seats => 5, :maxspeed => 210))
      Car.create(car_create_values(:num_seats => 3, :maxspeed => 210))
    }

    all_cars               = 0
    cars_with_4_seats      = 0
    cars_with_maxspeed_200 = 0
    query = (Car.select { |c| c.where(c.num_seats == 4); } + 
             Car.select { |c| c.where(c.maxspeed >= 200); c.order_by(:num_seats) })
    query.each { |car|
      cars_with_4_seats +=1 if car.num_seats.to_i == 4
      cars_with_maxspeed_200 +=1 if car.maxspeed.to_i >= 200
      all_cars += 1
    }

    

    cars_with_4_seats.should == 10
    cars_with_maxspeed_200.should == 20
    all_cars.should == 30
  end

end

