
$:.push('/opt/local/lib/ruby/1.8/postgres')

require('postgres')
require('lore')
require('lore/exceptions/database_exception')
require('lore/adapters/context')
require('lore/adapters/postgres/result')

module Lore

class Connection 

  @@query_count      = 0
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
        Lore.query_logger.debug { "  sql|#{Context.get_context}|----------------------" }
        query.split("\n").each { |line|
          Lore.query_logger.debug { "  sql|#{Context.get_context}| #{line}" }
        }
      end
    rescue ::Exception => pge
      pge.message << "\n" << query.inspect
      Lore.logger.error { pge.message }
      Lore.logger.error { 'Context: ' << Context.inspect }
      Lore.logger.error { 'Query: ' << "\n" << query }
      raise Lore::Exceptions::Database_Exception.new(pge.message << "\n" << query.to_s)
    end
    
    return Result.new(query, result)
  end

  def self.establish(db_name)
    begin
      PGconn.connect(Lore.pg_server, 
                     Lore.pg_port, 
                     '', '', 
                     db_name.to_s, 
                     Lore.user_for(db_name.to_sym), 
                     Lore.pass_for(db_name.to_sym))
    rescue ::Exception => e
      raise Lore::Exceptions::Database_Exception.new(e.message)
    end
  end

  def self.commit_transaction(tx)
    perform('COMMIT')
  end

  def self.begin_transaction(tx)
    perform('BEGIN')
  end

  def self.rollback_transaction(tx)
    perform('ROLLBACK')
  end

  def self.add_savepoint(tx)
    perform("SAVEPOINT #{Context.current}_#{tx.depth}")
  end
  
end # class Connection

end # module Lore
