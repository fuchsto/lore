
require 'spec_env'
include Lore::Spec_Fixtures::Models


describe(Lore::Transaction) do
  before do
    flush_test_data()
  end

  it "performs rollbacks on errors" do
    STDERR.puts 'SIMPLE ROLLBACK'
    owner_id = false
    begin
      Lore::Transaction.exec { |t|
        owner = Owner.create(:name => 'Filou')
        owner_id = owner.owner_id
        raise ::Exception.new('forced')
      }
    rescue ::Exception => e
      e.message.should == 'forced'
    end
    
    Owner.get(owner_id).should == false
  end

  it "allows reentrant usage" do
    STDERR.puts 'REENTRANT'
    Lore::Transaction.exec { |t|
      owner = Owner.create(:name => 'Filou')
      manuf = Manufacturer.create(:name => 'Ford')
      Lore::Transaction.exec { |t|
        motor = Motor.create(:motor_name => 'Ford V8', :kw => 120)
        type  = Car_Type.create(:type_name => 'Limousine')
        v = Car.create(:name        => 'Ford Mondeo', 
                       :motor_id    => motor.pkey,
                       :num_doors   => 3, 
                       :num_seats   => 100, 
                       :maxspeed    => 180, 
                       :car_type_id => type.pkey, 
                       :manuf_id    => manuf.pkey, 
                       :owner_id    => owner.pkey)
      }
    }
  end

  it "provides savepoints" do
    STDERR.puts 'SAVEPOINTS'
    car_id   = false
    manuf_id = false
    owner_id = false
    begin
      Lore::Transaction.exec { |t|
        owner    = Owner.create(:name => 'Filou')
        owner_id = owner.owner_id
        manuf    = Manufacturer.create(:name => 'Ford')
        manuf_id = manuf.manuf_id
        t.save

        motor = Motor.create(:motor_name => 'Ford V8', :kw => 120)
        type  = Car_Type.create(:type_name => 'Limousine')
        car   = Car.create(:name        => 'Ford Mondeo', 
                           :motor_id    => motor.pkey,
                           :num_doors   => 3, 
                           :num_seats   => 100, 
                           :maxspeed    => 180, 
                           :car_type_id => type.pkey, 
                           :manuf_id    => manuf.pkey, 
                           :owner_id    => owner.pkey)
        car_id = car.car_id
        raise ::Exception.new('forced')
      }
    rescue ::Exception => e
      e.message.should == 'forced'
    end
    Car.get(car_id).should == false
    Owner.get(owner_id).name.should == 'Filou'
    Manufacturer.get(manuf_id).name.should == 'Ford'
  end

end

