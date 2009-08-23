
require 'rubygems'
require 'lore'
require 'lore/model'


Lore.logfile = STDERR
Lore.enable_query_log
Lore.logger.level       = Logger::ERROR
Lore.query_logger.level = Logger::ERROR
Lore.add_login_data 'test' => [ 'cuba', 'cuba23' ]
Lore::Context.enter :test

require './fixtures/models'
require './fixtures/blank_models'
require './fixtures/polymorphic_models'
require './spec_helpers'

