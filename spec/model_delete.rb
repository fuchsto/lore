
require 'spec_env'
include Lore::Spec_Fixtures::Models

describe(Lore::Table_Accessor) do

  it "does not delete records for aggregated models on delete procedures" do
    vehicle  = Motorized_Vehicle.find(1).entity  # Any will do
    motor_id = vehicle.motor.motor_id
    motor    = Motor.get(motor_id) # Re-Select to be sure
    vehicle.delete!
    test     = Motor.get(motor_id) # Re-Select to be sure
    test.should_not == false
  end

end

