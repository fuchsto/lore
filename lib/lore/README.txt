
Q: Are there adapters for other DBMS than PostgreSQL?
A: PostgreSQL is - to me and everyone using Lore i know of - 
   the best (free) choice for sophisticated database-driven 
   apps, so frankly said: Implementing adapters is not on my
   top priority list. 
   So far, Lore supports PostgreSQL (7.4 to 8.3 tested). 
   Adapters are planned for oracle mysql and sqlite though. 
   Lore is SQL 92 compatible and not using any exotic 
   Postgres features, so it *might* work fine on e.g. mysql 
   and sqlite with just minor modifications. Lore is caring 
   about cascading dependencies etc itself, so you don't even 
   need foreign keys or table inheritance. 
   You will have to change the code establishing DB 
   connections (see connection.rb), but as those are 
   abstracted, just a couple of lines of code in connection.rb
   had to be changed. 

Q: How do i establish a DB connection at all? 
A: First provide login data for a database (aka Context): 

     Lore.add_login_data('dbname' => ['user', 'pass'])
     Lore.add_login_data('other_dbname' => ['user', 'pass'])

   Now, activate a context. You can stack them, too: 

     Lore::Context.enter :dbname
     # Operate in database dbname
       Lore::Context.enter :other_dbname
       # Operate in database other_dbname
       Lore::Context.leave
     # Operate in database dbname
     Lore::Context.enter :other_dbname

Q: What about connection pooling? 
A: Lore re-uses connections per-process, that is: There is 
   one connection for every context you entered in every 
   process Lore is running in. 
   In case you need connections shared over multiple 
   processes, use PGPool for that, it's way better than any 
   implementation of connection pooling in ruby. 
   Install PGPool and tell lore to connect to PGPool's port 
   instead of PostgreSQL's one. 
   Example: 

      Lore.server = 'localhost:9999'

   That's it! 

Q: Which solution do you recommend for query result caching? 
A: There are many possibilities: Tempfiles, Mmap and Memcached
   are the most widespread solutions known to me. 
   Many will agree that MMap is the best solution in matters 
   of performance on a single server, and memcached as soon as
   more than one server is involved in your application. 
   To enable caching for all models: 

     Lore::Model.use_entity_cache Lore::Cache::Mmap_Entity_Cache
   or
     Lore::Model.use_entity_cache Lore::Cache::Memcached_Entity_Cache

Q: After creating a model via Model_Factory: How do i change 
   it? 
A: At the moment, this is not implemented, but tracked as 
   'missing feature'. This will be possible in version 1.0 at 
   the latest. 

Q: Where to look for documentation and examples? 
A: Have a look at the wiki. I'm updating it quite often, and 
   new features are explained in the wiki first: 
   http://infranode.com/wiki/

Q: I found a bug!! What now?
A: In case you're registered at rubyforge, visit 
   http://lore.rubyforge.org and submit a bug report. 
   Otherwise, just send me a mail (fuchs@atomnode.net). 
   If you're using Lore and are your progress is blocked by a 
   bug, i'll fix it almost instantly. I'm checking my mails 
   more often than the tickets at rubyforge, though. 

Q: I want to join the dev team. 
A: Great! Just send a mail to fuchs@wortundform.de, i will add 
   you on Rubyforge if you got some code to share. 
   
