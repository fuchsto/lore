
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
  Lore::Spec_Fixtures::Models::Vehicle.delete_all
  Lore::Spec_Fixtures::Models::Motorized_Vehicle.delete_all
  Lore::Spec_Fixtures::Models::Car.delete_all
  Lore::Spec_Fixtures::Models::Motorbike.delete_all
  Lore::Spec_Fixtures::Models::Garage.delete_all
  Lore::Spec_Fixtures::Models::Owner.delete_all
  Lore::Spec_Fixtures::Models::Vehicle_Owner.delete_all
end

