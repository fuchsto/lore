
require('rubygems')
begin
 require('pg')
 require('lore/adapters/postgres/connection')
 require('lore/adapters/postgres/result')
 require('lore/adapters/postgres/types')
 require('lore/adapters/postgres/sequence')
rescue LoadError => le
  Lore.logger.warn { "Could not load pg: " + le.to_s } 
  begin
    Lore.pg_server = 'unix:/var/run/postgresql/.s.PGSQL.5432'
    Lore.logger.info { "Defaulted PG server to #{Lore.pg_server}" }
    Lore.logger.info { "Use Lore.pg_server = 'server uri' to set a different one" } 
  # Bridges PostgresPR::Connection to PGConn
  # require 'postgres-pr/postgres-compat'
    require('postgres-pr/connection')
    require('lore/adapters/postgres-pr/connection')
    require('lore/adapters/postgres-pr/result')
    require('lore/adapters/postgres-pr/types')
    require('lore/adapters/postgres-pr/sequence')
  rescue LoadError => le
    Lore.logger.error { "No binding for postgres found" }
    Lore.logger.error { "Please install gem 'pg' or 'postgres-pr'" }
    raise le
  end
end
