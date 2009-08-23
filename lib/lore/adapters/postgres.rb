
require('rubygems')
begin
  require('postgres')
  require('lore/adapters/postgres/connection')
  require('lore/adapters/postgres/result')
  require('lore/adapters/postgres/types')
rescue LoadError
  Lore.pg_server = 'unix:/var/run/postgresql/.s.PGSQL.5432'
# Bridges PostgresPR::Connection to PGConn
# require 'postgres-pr/postgres-compat'
  require('lore/adapters/postgres-pr/connection')
  require('lore/adapters/postgres-pr/result')
  require('lore/adapters/postgres-pr/types')
end

