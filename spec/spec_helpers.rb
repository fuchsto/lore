
class Array
  def should_be(other)
    other.length.should == self.length
    self.each_with_index { |value, idx|
      other[idx].should == value
    }
  end

  def should_include(value)
    self.include?(value).should == true
  end
end

class Hash

  def should_be(other)
    num_keys = keys.length
    num_keys.should == other.keys.length

    self.each_pair { |key, value|
      other.keys.should_include key
      if value.is_a?(Hash) then
        value.should_be(other[key])
      elsif value.is_a?(Array) then
        value.should_be(other[key])
      else
        other[key].should == value
      end
    }
  end

end

def flush_test_data()
  require './fixtures/models'
  Lore.query_logger.debug { '-------- BEGIN FLUSH --------' }
  Lore::Spec_Fixtures::Models::Vehicle.delete_all
  Lore::Spec_Fixtures::Models::Motorized_Vehicle.delete_all
  Lore::Spec_Fixtures::Models::Car.delete_all
  Lore::Spec_Fixtures::Models::Motorbike.delete_all
  Lore::Spec_Fixtures::Models::Garage.delete_all
  Lore::Spec_Fixtures::Models::Owner.delete_all
  Lore::Spec_Fixtures::Models::Vehicle_Owner.delete_all
  Lore.query_logger.debug { '-------- END FLUSH ----------' }
end

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
