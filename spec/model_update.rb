
require 'spec_env'
include Lore::Spec_Fixtures::Models

include Spec_Model_Select_Helpers

describe(Lore::Table_Accessor) do
  before do
    flush_test_data()
  end

  it "provides a DSL for updating models" do
    car = Car.create(car_create_values)

    Car.update { |c|
      c.where(c.id == car.pkey)
      c.set(:num_doors => 20)
    }

    car_sel = Car.load(:id => car.pkey)
    car_sel.num_doors.should == 20
  end

  it "changes field values on #[:field_name] = value" do
    car = Car.create(car_create_values(:num_doors => 4))
    car[:num_doors] = 10
    car.num_doors.should == 10
    car.commit
    car.num_doors.should == 10
    car_sel = Car.load(:id => car.pkey)
    car_sel.num_doors.should == 10
  end

  it "changes field values on #field_name = value" do
    car = Car.create(car_create_values(:num_doors => 4))
    car[:num_doors] = 10
    car.num_doors.should == 10
    car.commit
    car.num_doors.should == 10
    car.set_attribute_value(:num_doors, 10)
    car_sel = Car.load(:id => car.pkey)
    car_sel.num_doors.should == 10
  end

end
