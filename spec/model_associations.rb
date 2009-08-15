

describe(Lore::Table_Accessor) do
  before do
    require 'lore/model'
    require './spec/fixtures/models'
  end

  it "is assigned to a base table" do
    Car.table_name.should == 'public.car'
    Vehicle.table_name.should == 'public.vehicle'
  end

  it "loads attribute fields automatically as array of symbols" do
    Vehicle.fields.should == [ :vehicle_id ] 
  end

  it "inherits attribute fields from base models it is derived from" do
    Car.fields.should == [ ]
  end


end
