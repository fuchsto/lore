
require 'spec_env'

include Lore::Spec_Fixtures::Models

describe(Lore::Clause) do

  it "is assigned to a concrete table field" do
    Car.maxspeed.to_s.should  == 'public.vehicle.maxspeed'
    Car.num_seats.to_s.should == 'public.vehicle.num_seats'
    Car.num_doors.to_s.should == 'public.car.num_doors'
    Car.name.to_s.should      == 'public.vehicle.name'
  # should agggregates be included? 
  # Car.type_name.to_s.should == 'public.car_type.type_name 
  end

  it "has comparison operators like >, <, <=>, <=, >= and some aliases" do
    (Car.maxspeed > 100).to_s.should == "public.vehicle.maxspeed > '100'"
    (Car.num_doors == 4).to_s.should == "public.car.num_doors = '4'"
    (Car.num_seats <= 5).to_s.should == "public.vehicle.num_seats <= '5'"
  end

  it "has special SQL comparison operators such as between, like, ilike" do
    Car.name.like('%wombat').to_s.should == "public.vehicle.name LIKE '%wombat'"
  end

  it "has logical operators like & and |" do
    clause = Car.name.ilike('%knurt%').and(Car.num_doors.is(3))
    clause.to_sql.should == "(public.vehicle.name ILIKE '%knurt%' AND public.car.num_doors = '3')"

    or_clause = (Vehicle.num_seats.in(1..5))
    or_clause.to_sql.should == "public.vehicle.num_seats BETWEEN 1 AND 5 "

    (clause | or_clause).to_sql.should == "((public.vehicle.name ILIKE '%knurt%' AND public.car.num_doors = '3') OR public.vehicle.num_seats BETWEEN 1 AND 5 )"
  end

end
