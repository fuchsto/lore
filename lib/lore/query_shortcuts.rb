
module Lore

  class Refined_Query

    def initialize(accessor, statements={})
      @accessor  = accessor
      @condition = statements[:condition]
      @what      = statements[:what]
      @limit     = statements[:limit]
      @offset    = statements[:offset]
      @order_by  = statements[:order_by]
      @order_by  = Array.new unless @order_by
      @group_by  = statements[:group_by]
      @having    = statements[:having]
      @condition = true unless @condition
#     @what = @what.to_s unless @what.nil?
    end

    # Example: 
    # Adds where-condition to query. Multiple calls stack using AND. Examples; 
    # 
    #   Type.find(1).with(Type.name == 'foo' & Type.position > 2).having(<...>).ordered_by(:name).result 
    #   # ... is same as ...
    #   Type.find(1).with(Type.name == 'foo').with(Type.position > 2).having(<...>).ordered_by(:name).result 
    #
    #   User.all.with(User.user_id.in( Admin.all(:user_id) ))
    #
    def with(condition)
      if((@condition.instance_of? TrueClass) || @condition.nil?) then 
        @condition = condition 
      elsif(condition.is_a? Hash) then
        @condition = condition
      else
        @condition = (@condition & condition)
      end
      return self
    end
    alias where with

    def or(condition)
      @condition = ((@condition) | condition)
      return self
    end

    # Adds HAVING statement to query. Examples: 
    # 
    #   User.all.having(User.user_id.in( Admin.all(:user_id) ))
    # 
    def having(having_clause)
      @having = having_clause
      return self
    end

    # To be overloaded by derived classes
    def perform
    end

    # Provides wrapper for simple SQL attribute operation keywords. 
    # Examples: 
    #
    #   Car.value_of.sum(Car.car_id).to_i   
    #   -> SELECT sum(public.car.car_id) ...
    #   -> Amount of all cars as integer, e.g. 2342
    #   Car.value_of.max(Car.car_id).to_i   
    #   -> SELECT max(public.car.car_id) ...
    #   -> Highest car_id as integer, e.g. 14223
    #
    def method_missing(method, attribute_name)
      @what = "#{method.to_s}(#{attribute_name.to_s}) "
      return self
    end

  end # class
  
  class Refined_Select < Refined_Query

    def initialize(accessor, statements={})
      @polymorphic = false
      super(accessor, statements)
    end

    # Examples: 
    # 
    # Initiates request for single attribute values instead 
    # model instances. Returns value as string, array or two-dimensional 
    # array, depending from parameters passed: 
    # 
    #   Car.find(2).values_of(Car.name, Car.id).ordered_by(Car.name, :asc).entities 
    #   -> [ ['BMW318i', '3'], ['BMW Mini', '5'] ]
    #   Car.find(2).values_of(Car.name).ordered_by(Car.name, :asc).entities   
    #   -> [ 'BMW318i', 'BMW Mini']
    #   Car.find(1).value_of(Car.name, Car.type).with(Car.name.ilike '%BMW%').entity 
    #   -> ['BMW318i', 'Convertible']
    #   Car.find(1).value_of(Car.name).with(Car.name.ilike '%BMW%').entity 
    #   -> 'BMW318i'
    #
    def values_of(*what)
      @what = what
      return self
    end
    alias value_of values_of

    # Same as #entities.first. Useful when requesting one row or a single 
    # attribute only. 
    def entity
      entities.first
    end
    
    def first
      entities.first
    end


    # When requesting a single value, #to_i can be used to 
    # retreive the result as string instead of calling #entity:
    # 
    #   s1 = User.all(User.name).with(User.name.like '%Christina%').to_s
    #   s2 = User.all(User.name).with(User.name.like '%Christina%').entity
    #   assert_equal s1, s2
    #
    def to_s
      entities.first.to_s
    end
    # When requesting a single value, #to_i can be used to 
    # retreive the result as integer instead of calling #entity: 
    # 
    #   i1 = User.all(User.id).with(User.name.like '%Christina%').to_i
    #   i2 = User.all(User.id).with(User.name.like '%Christina%').entity.to_i
    #   assert_equal i1, i2
    #
    def to_i
      entities.first.to_s.to_i
    end

    # Adds order statement to query. Direction is either :desc or :asc. 
    # Example: 
    # 
    #   User.find(0..10).ordered_by(:surname, :asc)
    #   User.find(20).ordered_by([:surname, :forename], :desc)
    # 
    # Aliases are #order_by and #sort_by. 
    # 
    def ordered_by(attrib, dir=:asc)
      @order_by << [attrib, dir]
      return self
    end
    alias order_by ordered_by
    alias sort_by ordered_by

    # Offset part of a query. 
    #
    #   Something.find(10).with(Something.name == 'foo').offset(123).entities
    # Results in 
    #   SELECT * FROM something WHERE something.name = 'foo' LIMIT 10,123
    #
    def offset(off)
      @offset = off
      return self
    end

    # Limit part of a query. 
    #
    #   Something.all_with(Something.name == 'foo').limit(10,123).entities
    # Is same as 
    #   Something.find(10).with(Something.name == 'foo').offset(123).entities
    # Is same as 
    #   Something.find(10,123).with(Something.name == 'foo').entities
    #
    # And results in 
    #   SELECT * FROM something WHERE something.name = 'foo' LIMIT 10,123
    #
    def limit(lim, off=0)
      @limit = lim
      @offset = off
      return self
    end

    # Execute as polymorphic query, joining all concrete base models 
    # of this polymorhpic model. 
    def polymorphic
      @polymorphic = true
      return self
    end

    # Handy wrapper for 
    #   <request>.entities.each { |e| ... }
    def each(&block)
      entities.each &block
    end

    # Returns Clause instance containing this select statement. 
    # This is needed for all Clause methods expecting an inner select. 
    # Example: 
    #
    #   inner = Car.all(Car.car_id).with(Car.seats > 2)
    #   Car.all.where(Car.car_id).in(inner)  # method 'in' calls inner.to_select
    #
    # Full example: 
    #
    #   Car.all.where(Car.car_id).in( 
    #     Manufacturer_Car.values_of(Manufacturer_Car.car_id).limit(10).sort_by(Manufacturer_Car.name)
    #   )
    #
    def to_select
      @accessor.select(@what) { |entity|
        entity.where(@condition)
        entity.limit(@limit, @offset) unless @limit.nil?
        @order_by.each { |o|  
          entity.order_by(o[0], o[1]) 
        }
        entity.group_by(@group_by) unless @group_by.nil?
        entity.having(@having) unless @having.nil?
        entity
      }
    end

    # Sends request defined by previous method calls to self. Examples: 
    # 
    #   Car.find(10).with(Car.name.like '%BMW%').entities  # -> Array of 10 instances of model klass 'Car'
    # 
    # Before calling #entities, the request isn't sent, but defined only. 
    # Therefore you safely can pass a query (Clause) object to other methods, 
    # like in this example: 
    # 
    #   def filter_cars(clause)
    #     query.with((Car.name != '') & clause).limit(10).entities
    #   end
    #
    #   filder = Car.find(10).with(Car.name.like '%Audi%').limit(20) # Request is not sent yet
    #   filter_cars(filter) # Request will be sent here
    #   # -> Car.find(10).with(Car.name.like '%Audi%').with(Car.name != '').limit(10).entities
    #   # -> Car.find(10).with((Car.name.like '%Audi%') & (Car.name != '')).limit(10).entities
    # 
    # There are other methods not defining but executing a request: 
    # #entity, #each, #to_i, #to_s
    #
    def entities
      if @what.nil? then
        if @polymorphic then
          result = @accessor.polymorphic_select { |entity|
            entity.where(@condition)
            entity.limit(@limit, @offset) unless @limit.nil?
            @order_by.each { |o|  
              entity.order_by(o[0], o[1]) 
            }
            entity.group_by(@group_by) unless @group_by.nil?
            entity.having(@having) unless @having.nil?
            entity
          }.to_a
        else
          result = @accessor.select { |entity|
            entity.where(@condition)
            entity.limit(@limit, @offset) unless @limit.nil?
            @order_by.each { |o|  
              entity.order_by(o[0], o[1]) 
            }
            entity.group_by(@group_by) unless @group_by.nil?
            entity.having(@having) unless @having.nil?
            entity
          }.to_a
        end
      else
        result = Array.new
        @accessor.select_values(@what) { |entity|
          entity.where(@condition)
          entity.limit(@limit, @offset) unless @limit.nil?
          @order_by.each { |o|  
            entity.order_by(o[0], o[1]) 
          }
          entity.group_by(@group_by) unless @group_by.nil?
          entity.having(@having) unless @having.nil?
          entity
        }.each { |row|
          if row.kind_of? Hash then
            result << row.values['value'] 
          else 
            result << row
          end
        }
      end

      return result
    end
    alias perform entities
    alias to_a entities
    alias result entities
    alias value entity

  end # class

  class Refined_Delete < Refined_Query

    def perform
      @accessor.delete { |entity|
        entity.where(@condition)
        entity.limit(@limit, @offset) unless @limit.nil?
        entity.having(@having) unless @having.nil?
        entity
      }
    end

  end # class

  class Refined_Update < Refined_Query
    
    def initialize(accessor, statements={})
      @update_values = statements[:update_values]
      super(accessor, statements)
    end

    def perform
      @accessor.update { |entity|
        entity.set(@update_values)
        entity.where(@condition)
        entity
      }
    end

  end


  module Query_Shortcuts

    # Example: 
    #
    #  Users.value_of.sum(:user_id)
    #
    def value_of(what=nil)
      Refined_Select.new(self, :condition => true, :what => what)
    end
    alias values_of value_of
    alias all value_of

    # Wrapper for 
    #
    #   Accessor.all.entities.each { |e| ... }
    #
    def each(&block)
      all.entities.each(&block)
    end

    # Returns Refined_Select instance with limit set to amount. 
    # Example: 
    #   
    #   Car.find(10).with(...) ...
    #
    def find(amount, offset=0)
      if amount == :all then
        all()
      else
        Refined_Select.new(self, :limit => amount, :offset => offset)
      end
    end

    # Returns Refined_Select instance with WHERE statement set 
    # to condition. 
    # Same as 
    #
    #   Accessor.find(:all).with(condition)
    # or
    #   Accessor.all.with(condition)
    #
    def all_with(condition)
      Refined_Select.new(self, :condition => condition)
    end
    
    # Example:
    #
    #   Accessor.set(:attribute => 'value').where(...).perform
    #
    def set(values)
      Refined_Update.new(self, :update_values => values)
    end

    # Example:
    #
    #   Accessor.delete.where(...).perform
    #
    def delete
      Refined_Delete.new(self)
    end
    
    # Deletes all entities of model class, i.e. empties its tables (!). 
    # Example: 
    #
    #   Car.delete_all
    #
    def delete_all
      delete { |entity|
        entity.where(true)
      }
    end

  end # module

end # module
