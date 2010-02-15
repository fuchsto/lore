
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
    Lore::Transaction.exec { |t|
      owner  = Owner.create(:name => 'Filou')
      manuf  = Manufacturer.create(:name => 'Ford')
      car_id = false
      t.save
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
        car = v.car_id
      }
    }
  end

end

