
require 'rubygems'
require 'lore'
require 'lore/model'
require 'lore/exceptions/validation_failure'


Lore.logfile = STDERR
Lore.enable_query_log
Lore.logger.level       = Logger::DEBUG
Lore.query_logger.level = Logger::DEBUG
# Lore.add_login_data 'test' => [ 'paracelsus', nil ]
Lore.add_login_data 'test' => [ 'cuba', 'cuba23' ]
Lore::Context.enter :test

require './fixtures/models'
require './fixtures/blank_models'
require './fixtures/polymorphic_models'
require './spec_helpers'

