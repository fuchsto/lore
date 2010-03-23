
require('lore')

module Lore

class Connection_Error < ::Exception

end

class Context 
  
  @@context_stack = Array.new
  
  def self.get_connection()
    if @@context_stack.empty? then
      raise ::Exception.new('No context given. ')
    end
    return Connection_Pool.get_connection(@@context_stack.last)
  end

  def self.get_context
    @@context_stack.last
  end
  def self.current
    @@context_stack.last
  end

  def self.inspect
    @@context_stack.inspect
  end
  
  def self.enter(context_name)
    Lore.logger.debug { "Entering context #{context_name}" }
    @@context_stack.push(context_name.to_sym)
  end
  
  def self.leave()
    context_name = @@context_stack.pop
    Lore.logger.debug { "Leaving context #{context_name}" } 
  end
  
end
  
class Connection_Pool 

  @@pool = Hash.new

  def self.get_connection(db_name)
    
    db_name = db_name.to_sym
    
    # If requested connection is not in pool yet: 
    if !@@pool.has_key? db_name then
    # Try to establish connection
      connection = Lore::Connection.establish(db_name)
      connection.exec(Lore.on_connect_commands)
      @@pool[db_name] = connection
    end

    # Return requested connection
    return @@pool[db_name]

  end

end

end # module Lore
