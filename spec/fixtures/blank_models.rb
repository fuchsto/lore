
module Lore
module Spec_Fixtures
module Blank_Models

  class Vehicle < Lore::Model
  end

  class Motor < Lore::Model
  end

  class Motorized_Vehicle < Lore::Model
  end

  class Car < Vehicle
  end

  class Motorbike < Vehicle
  end

  class Owner < Lore::Model
  end

  class Vehicle_Owner < Lore::Model
  end

  class Car_Type < Lore::Model
  end

  class Garage < Lore::Model
  end

end
end
end
