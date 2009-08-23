
$:.push('/opt/local/lib/ruby/1.8/postgres')

require('postgres-pr/connection')
require('lore')
require('lore/exceptions/database_exception')
require('lore/adapters/context')
require('lore/adapters/postgres-pr/result')
require('lore/adapters/postgres-pr/types')

module PostgresPR
  class Connection
    alias exec query
    alias exec_async query
  end
end

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
    # result = Context.get_connection.exec(query)
      result = Context.get_connection.query(query)
      @@result_row_count += result.rows.length
      
      if Lore.log_queries? then
        query.split("\n").each { |line|
          Lore.query_logger.debug { "  sql|#{Context.get_context}| #{line}" }
        }
      end
    rescue ::Exception => pge
      Lore.logger.error { pge.message }
      Lore.logger.error { 'Context: ' << Context.inspect }
      Lore.logger.error { 'Query:   ' << "\n" << query }
      raise pge
      raise Lore::Exceptions::Database_Exception.new(pge.message << "\n" << query.to_s)
    end
    
    return Result.new(query, result)
  end

  def self.establish(db_name)
    Lore.logger.info { "Establishing connection to #{db_name}" }
    Lore.logger.info { "User: #{Lore.user_for(db_name.to_sym).inspect}"}
    Lore.logger.info { "Pass: #{Lore.pass_for(db_name.to_sym).inspect}"}
    Lore.logger.info { "Server: #{Lore.pg_server}" }
    begin
      PostgresPR::Connection.new(db_name.to_s, 
                                 Lore.user_for(db_name.to_sym), 
                                 Lore.pass_for(db_name.to_sym), 
                                 # including port, example: 
                                 # 'unix:/var/run/postgresql/.s.PGSQL.5432'
                                 Lore.pg_server)
    rescue ::Exception => e
      raise Lore::Exceptions::Database_Exception.new(e.message)
    end
  end
  
end # class Connection

end # module Lore
