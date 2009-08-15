
require 'rake'

spec = Gem::Specification.new { |s|

  s.name = 'lore' 
  s.rubyforge_project = 'lore'
  s.summary = 'A flexible ORM based on PostgreSQL'
  s.description = <<-EOF
    Lore is an object-relational mapping (ORM) implementation 
    providing many features like prepared statements, 
    (multiple) inheritance, a comfortable query syntax, 
    highly customizable automated form generation, 
    and result caching using memory mapping (MMap). 
    It aims at performance, usability and - unlike most ORMs - 
    high coverage of native SQL functions and features. 
    Lore is currently using PostgreSQL as database backend. 
  EOF
  s.version = '0.5.0'
  s.author = 'Tobias Fuchs'
  s.email = 'fuchs@wortundform.de'
  s.date = Time.now
  s.files = '*.rb'
  s.add_dependency('postgres', '>= 0.1')
  s.add_dependency('aurita-gui', '>= 0.2')
  s.files = FileList['*', 
                     'lib/*', 
                     'lib/lore/*', 
                     'lib/lore/behaviours/*', 
                     'lib/lore/cache/*', 
                     'lib/lore/validation/*', 
                     'lib/lore/gui/*', 
                     'lib/lore/gui/templates/*', 
                     'lib/lore/exception/*', 
                     'bin/*', 
                     'test/*'].to_a

  s.has_rdoc = true
  s.rdoc_options << '--title' << 'Lore ORM' <<
                    '--main' << 'Lore::Model' <<
                    '--line-numbers'

  s.homepage = 'http://lore.rubyforge.org'

}
