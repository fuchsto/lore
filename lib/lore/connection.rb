
$:.push('/opt/local/lib/ruby/1.8/postgres')

require('postgres')
require('logger')
require('lore')
require('lore/result')

module Lore

class Connection_Error < ::Exception

end

class Context 
  
  @@logger = Lore.logger
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

  def self.inspect
    @@context_stack.inspect
  end
  
  def self.enter(context_name)
    Lore.log { 'Entering context ' + context_name.to_s }
    @@context_stack.push(context_name)
  end
  
  def self.leave()
    context_name = @@context_stack.pop
    @@logger.debug('Leaving context ' << context_name.to_s)
  end
  
end
  
class Connection_Pool 

  @@pool = Hash.new

  def self.get_connection(db_name)
    
    db_name = db_name.intern unless db_name.instance_of? Symbol
    
    # If requested connection is not in pool yet: 
    if !@@pool.has_key? db_name then
      # Try to establish connection
      begin
        connection = PGconn.connect(Lore.pg_server, Lore.pg_port, '', '', db_name.to_s, Lore.user_for(db_name), Lore.pass_for(db_name.to_s))
        connection.exec(Lore.on_connect_commands)
        @@pool[db_name] = connection
      # Handle errors
      rescue PGError => pge
        raise Lore::Connection_Error.new("Could not establish connection to database '#{db_name.to_s}': " << pge.message)
      rescue ::Exception => excep
        raise Lore::Connection_Error.new("Could not establish connection to database '#{db_name.to_s}': " << excep.message)
      end
    end

    # Return requested connection
    return @@pool[db_name]

  end

end

class Connection # :nodoc
  #include Singleton

  @@logger = Lore.logger
  @@query_count = 0
  @@result_row_count = 0
  
  def initialize
  end
  
  def self.reset_query_count
    @@query_count = 0
  end
  def self.reset_result_row_count
    @@result_row_count = 0
  end
  def self.query_count
    @@query_count
  end
  def self.result_row_count
    @@result_row_count
  end
  
  def self.perform_cacheable(query)
    if Lore::Cache::Cached_Entities.include?(query) then
        result = Lore::Cache::Cached_Entities[query]
    else
      result = perform(query)
      Lore::Cache::Cached_Entities[query] = result
    end
    return result
  end
  
  def self.perform(query)
    begin
      @@query_count += 1
    # result = Context.get_connection.async_exec(query)
      result = Context.get_connection.exec(query)
      @@result_row_count += result.num_tuples
      
      if Lore.log_queries? then
        query.split("\n").each { |line|
          Lore.query_logger.debug { "  sql|#{Context.get_context}| #{line}" }
        }
      end
    rescue ::Exception => pge
      pge.message << "\n" << query.inspect
      Lore.logger.error { pge.message }
      Lore.logger.error { 'Context: ' << Context.inspect }
      Lore.logger.error { 'Query: ' << "\n" << query }
      raise ::Exception.new(pge.message << "\n" << query.to_s)
    end
    
    return Result.new(query, result)
  end
  
end # class Connection

end # module Lore
