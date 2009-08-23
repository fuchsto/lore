
require 'rake'

spec = Gem::Specification.new { |s|

  s.name = 'lore' 
  s.rubyforge_project = 'lore'
  s.summary = 'A flexible ORM based on PostgreSQL'
  s.description = <<-EOF
    Lore is an object-relational mapping (ORM) implementation 
    providing many features like prepared statements, 
    (multiple) inheritance, true polymorphism, a comfortable 
    query syntax, highly customizable automated form generation, 
    and result caching. 
    It aims at performance, usability and - unlike most ORMs - 
    high coverage of object oriented paradigms. 
    Lore is currently using PostgreSQL as database backend. 
  EOF
  s.version = '0.9.2'
  s.author  = 'Tobias Fuchs'
  s.email   = 'twh.fuchs@gmail.com'
  s.date    = Time.now
  s.files   = '*.rb'

# Remove dependency as postgres-pr would be ok, too
# s.add_dependency('postgres', '>= 0.1')
  s.requirements  = "A ruby binding for PostgreSQL, such as postgres or postgres-pr. "
  s.add_dependency('aurita-gui', '>= 0.2')
  s.files = FileList['*', 
                     'benchmark/*', 
                     'spec/*', 
                     'spec/fixtures/*', 
                     'lib/*', 
                     'lib/lore/*', 
                     'lib/lore/adapters/*', 
                     'lib/lore/cache/*', 
                     'lib/lore/exceptions/*', 
                     'lib/lore/gui/*', 
                     'lib/lore/gui/templates/*', 
                     'lib/lore/model/*', 
                     'lib/lore/strategies/*', 
                     'lib/lore/validation/*', 
                     'bin/*'].to_a

  s.has_rdoc = true
  s.rdoc_options << '--title' << 'Lore ORM' <<
                    '--main' << 'Lore::Model' <<
                    '--line-numbers'

  s.homepage = 'http://github.com/fuchsto/lore/'

}
