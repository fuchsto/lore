
require('logger')

module Lore
  
  VERSION='0.5.0'

  @logfile         = STDERR
  @query_logfile   = STDERR
  @log_queries     = true
  @logging_enabled = true
  @cache_entities  = false
  @pg_server = 'localhost'
  @pg_port   = 5432
  @logins = { }


  def self.logfile
    @logfile
  end
  def self.query_logfile
    @query_logfile
  end
  def self.logfile=(file)
    @logger       = Logger.new(file)
    @query_logger = Logger.new(file)
  end
  def self.query_logfile=(file)
    @query_logger = Logger.new(file)
  end
  def self.logger
    @logger
  end
  def self.query_logger
    @query_logger
  end

  @logger = Logger.new(Lore.logfile)
  @query_logger = Logger.new(Lore.query_logfile)

  def self.log(&log_block)
    return if Lore.logging_disabled?  
    Lore.logger.debug(&log_block)
  end

  def self.log_queries? 
    @log_queries && @logging_enabled
  end

  def self.disable_logging
    @logging_enabled = false
    Lore.logger.level = Logger::ERROR
  end
  def self.enable_logging
    @logging_enabled = true
    Lore.logger.level = Logger::DEBUG
  end
  def self.enable_query_log
    @log_queries = true
  end
  def self.disable_query_log
    @log_queries = false
  end
  def self.logging_disabled? 
    !@logging_enabled
  end

  def self.set_login_data(login_hash)
    @logins = login_hash
  end
  def self.add_login_data(login_hash)
    @logins.update(login_hash)
  end

  def self.path
    File.expand_path(File.dirname(__FILE__)) + '/'
  end

  def self.pg_server
    @pg_server
  end
  def self.pg_port
    @pg_port
  end
  def self.pg_server=(s)
    @pg_server = s
  end
  def self.pg_port=(p)
    @pg_port = p
  end

  def self.user_for(dbname)
    begin
      @logins[dbname.to_s][0].to_s
    rescue ::Exception => excep
      raise ::Exception.new('Unable to resolve user for database ' << dbname.inspect)
    end
  end
  def self.pass_for(dbname)
    @logins[dbname.to_s][1].to_s
  end

  def self.disable_cache
    @cache_entities = false
  end

  def self.enable_cache
    @cache_entities = true
  end

  def self.cache_enabled? 
    @cache_entities
  end

  def self.on_connect_commands()
    "set client_encoding to Unicode; set datestyle to 'European'"
  end

end

require('lore/validation/parameter_validator')
require('lore/exception/invalid_parameter')
require('lore/exception/invalid_klass_parameters')
require('lore/connection')
