
require('rubygems')
require('lore')
require('lore/model')
require('lore/cache/mmap_entity_cache')

Lore::Model.use_entity_cache Lore::Cache::Mmap_Entity_Cache
# Aurita.load_project :default
# Aurita.import_plugin_model :wiki, :article

# include Aurita::Plugins::Wiki

require('benchmark')
include Benchmark
# require('profile')
Lore.logfile = './benchmark_query.log'

require('rubygems')
require('activerecord')

ActiveRecord::Base.establish_connection(
  :adapter  => 'postgresql', 
  :host     => 'localhost', 
  :username => 'cuba', 
  :password => 'cuba23', 
  :database => 'artest'
)

Lore.add_login_data('artest' => ['cuba', 'cuba23'])
Lore::Context.enter :artest

module AR
  class Content < ActiveRecord::Base
  end

  class Article < Content
  end
end

module Lore
  class Content < Lore::Model
    table :contents, :public
    primary_key :id, :content_id_seq
  end

  class Article < Content
    table :articles, :public
    primary_key :id, :article_id_seq
    is_a Content, :content_id
  end

  Article.prepare(:id_in_range, Lore::Type.integer, Lore::Type.integer) { |a|
    a.where(Article.id.between('$1','$2'))
    a.limit(100)
  }


end

(0..3000).to_a.each { |i|
#  Lore::Article.create(:title => "title_#{i}", :text => "text #{i}")
}

num_loops = ARGV[0].to_i
num_loops ||= 1000

  class Result_Parser
  require 'inline'

    def initialize(result) # expects PGresult
      
      @result = result
      @field_types      = nil
      @result_rows      = Array.new
      @num_fields       = @result.num_fields
      @field_name_split = Array.new
      @field_name       = String.new
      @table_name       = String.new
      @field_counter    = 0
      
    end # def initialize

=begin
    inline { |builder|
      builder.c <<-EOC
        VALUE get_row_c(VALUE result, int row_num) { 
          unsigned int field_counter; 
          VALUE row_result, field_name, table_name, field_name_split; 
          VALUE value_set = rb_hash_new(); 
          field_name = rb_string_new(); 
          table_name = rb_string_new(); 
          row_result = rb_hash_new(); 
          for(field_counter = 0; field_counter < num_fields; field_counter++) { 
             value_set = result->getvalue(row_num, UINT2NUM(field_counter)); 
          // if(row_result[@table_name].nil?) then
             if(rb_hash_aref(row_result, table_name) == QNil) { 
            // row_result[@table_name] = Hash.new()
               rb_hash_aset(row_result, table_name, value_set)
             }
             rb_hash_aset(rb_hash_aref)row_result, table_name), value_set); 
          }
          return row_result; 
        }
      EOC
    }
=end

    def get_row(row_num=0)
      
      return if @result.num_tuples == 0

      row_result        = Hash.new
      
      @field_name_split = Array.new
      @field_name       = String.new
      @table_name       = String.new
      @field_counter = 0
      for @field_counter in 0...@num_fields do
        # admin.rd__content.name -> [admin, rd__content, name]
        @field_name = @result.fieldname(@field_counter)

        row_result[@field_name] = @result.getvalue(row_num,@field_counter)
      end
      
      @result_rows[row_num] = row_result
      
    end
    
    def get_rows()
      if !@result_rows.first then
        for tuple_counter in 0...@result.num_tuples do
          get_row(tuple_counter)
        end
      end
      @result_rows
    end

  end

db_name    = 'artest'
connection = PGconn.connect(Lore.pg_server, Lore.pg_port, '', '', db_name.to_s, Lore.user_for(db_name), Lore.pass_for(db_name.to_s))

sql = 'SELECT * 
        FROM public.articles
        JOIN public.contents on (public.contents.id = public.articles.content_id)
        WHERE public.articles.id BETWEEN 1100 AND 1200 LIMIT 100 OFFSET 0'

sql_exec = 'EXECUTE public_articles__id_in_range(1100,1200); '

sql_prep = 'PREPARE public_articles__id_in_range(integer,integer) AS
    SELECT
       public.contents.id AS "public.contents.id",
       public.contents.user_group_id AS "public.contents.user_group_id",
       public.contents.tags AS "public.contents.tags",
       public.contents.changed AS "public.contents.changed",
       public.contents.created AS "public.contents.created",
       public.contents.hits AS "public.contents.hits",
       public.contents.locked AS "public.contents.locked",
       public.contents.deleted AS "public.contents.deleted",
       public.contents.version AS "public.contents.version",
       public.articles.id AS "public.articles.id",
       public.articles.content_id AS "public.articles.content_id",
       public.articles.template_id AS "public.articles.template_id",
       public.articles.title AS "public.articles.title",
       public.articles.view_count AS "public.articles.view_count",
       public.articles.published AS "public.articles.published"
    FROM public.articles
    JOIN public.contents on (public.contents.id = public.articles.content_id)
    WHERE public.articles.id BETWEEN $1 AND $2  LIMIT 100  OFFSET 0'



bmbm(12) { |test|
  test.report("rows_raw") { 
    num_loops.times { 
      result = connection.exec(sql)
      for row in 0...result.num_tuples do
        for field_index in 0...result.num_fields do
          result.getvalue(row,field_index)
        end
      end
    }
  }
  test.report("rows_raw_parsed") { 
    num_loops.times { 
      result = connection.exec(sql)
      p = Result_Parser.new(result)
#     puts p.get_row_c(result, 0)
      p.get_rows
    }
  }
  test.report("rows_lore") { 
    num_loops.times { 
      result = connection.exec(sql)
      lore_result = Lore::Result.new('',result)
      lore_result.get_rows.each { |row|
        # noop
      }
    }
  }
  test.report("ac_instances") { 
    num_loops.times { 
      result = connection.exec(sql)
      lore_result = Lore::Result.new('',result)
      lore_result.get_rows.each { |row|
         i = Lore::Article.new(row)
      }
    }
  }
=begin
  test.report("ac_instances_prep") { 
    result = connection.exec(sql_prep)
    num_loops.times { 
      result = connection.exec(sql_exec)
      lore_result = Lore::Result.new('',result)
      model_instances = []
      lore_result.get_rows.each { |row|
         i = Lore::Article.new(Lore::Article,row)
         model_instances.push(i)
      }
    }
  }
=end
  test.report("full_auto") { 
    Lore.disable_cache
    num_loops.times { 
      Lore::Article.select { |a|
        a.where(a.id.in(1100..1200))
        a.limit(100)
      }
    }
  }
=begin
  test.report("lore_prepared") { 
    Lore.disable_cache
    num_loops.times { 
      Lore::Article.id_in_range(1100,1200)
    }
  }
=end
  test.report("ar") { 
    num_loops.times { 
      AR::Article.find(:all, :conditions => "id > 1100 AND id < 1200").each { |a|
      }
    }
  }
  test.report('using cache') { 
    Lore.enable_cache
    num_loops.times { 
      Lore::Article.find(100).with(Lore::Article.id.in(1100..1200)).entities
    }
  }
}


