
require 'rubygems'
require 'lore'
require 'lore/model'

include Lore

Lore.add_login_data 'lore' => [ 'cuba', 'cuba23' ]
Lore.logfile = STDERR
Lore.enable_logging
Lore.enable_query_log

class User < Model
  context :lore
  table :user_group, :internal
  primary_key :user_group_id, :user_group_id_seq
end

class Content < Model
  context :lore
  table :content, :public
  primary_key :content_id, :content_id_seq

  expects :tags
  has_a User, :user_group_id_f
end

class Article < Content
  context :lore
  table :article, :public
  primary_key :article_id, :article_id_seq

  is_a Content, :content_id_f
end

puts 'content implicit'
p Content.__attributes__.implicit
puts 'content pkeys'
p Content.__associations__.primary_keys
puts 'content fkeys'
p Content.__associations__.foreign_keys
puts 'content sequences'
p Content.__associations__.foreign_keys
puts 'content has_a'
p Article.__associations__.has_a
puts 'article implicit'
p Article.__attributes__.implicit
puts 'article types'
p Article.__attributes__.types
puts 'article pkeys'
p Article.__associations__.primary_keys
puts 'article fkeys'
p Article.__associations__.foreign_keys
puts 'article explicit'
p Article.__attributes__.explicit
puts 'article required'
p Article.__attributes__.required
puts 'article base_klasses_tree'
p Article.__associations__.base_klasses_tree
puts 'article sequences'
p Article.__attributes__.sequences
puts 'article all table names'
p Article.get_all_table_names

a = Article.load(:article_id => 1055)
p a

b = Article.find(1).with(Article.article_id == 1055).entity
puts 'Tag test:'
p b.tags
p b.tags.include?('a')

p Article.create(:title  => 'Created', 
                 :tags   => [ :a, :b, :c ], 
                 :locked => false)


