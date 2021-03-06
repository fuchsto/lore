
require 'spec_env'
include Lore::Spec_Fixtures::Models

describe(Lore::Table_Accessor) do

  before do
    flush_test_data()
  end

  it "can validate required attribute values to be set" do
    lambda { Vehicle.create() }.should raise_error(Lore::Exceptions::Validation_Failure)
    lambda { Vehicle.create(:name => 'first') }.should raise_error(Lore::Exceptions::Validation_Failure)
    lambda { Vehicle.create(:name => 'second', 
                            :maxspeed => 120, 
                            :num_seats => 4) }.should_not raise_error(Lore::Exceptions::Validation_Failure)
    v = nil # pre-def
    lambda { v = Vehicle.create(:name => '1@2foo', 
                                :maxspeed => 120, 
                                :num_seats => 4) }.should_not raise_error(Lore::Exceptions::Validation_Failure)
    v.name.should == '12foo'
  end
  
end
