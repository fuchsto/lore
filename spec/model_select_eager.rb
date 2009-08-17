
require 'spec_env'
include Lore::Spec_Fixtures::Models

describe(Lore::Table_Accessor) do
  before do
  end
  it "provides eager loading of 1:1 relations" do
    Lore::Connection.reset_query_count
    # First query
    car_1 = Car.find(1).with(Car.name == 'Ford').eager(Manufacturer).entity
    # Second query
    car_2 = Car.find(1, :eager => Manufacturer).with(Car.name == 'Ford').entity
    # Third query
    car_3 = Car.select(:eager => Manufacturer) { |c|
              c.where(c.name == 'Ford')
              c.limit(1)
            }.first

    Lore::Connection.num_queries.should == 3
    car_1.manufacturer.should_be car_2.manufacturer
    car_1.manufacturer.should_be car_3.manufacturer
  end

  it "provides eager loading of 1:n relations" do
    Lore::Connection.reset_query_count
    # Two queries
    car_1 = Car.find(1).with(Car.name == 'Ford').eager(Owner).entity
    # Two queries
    car_2 = Car.find(1, :eager => Owner).with(Car.name == 'Ford').entity
    # Two queries
    car_3 = Car.select(:eager => Owner) { |c|
              c.where(c.name == 'Ford')
              c.limit(1)
            }.first

    Lore::Connection.num_queries.should == 6
    car_1.owner_set.should_be car_2.owner_set
    car_1.owner_set.should_be car_3.owner_set
  end

end
