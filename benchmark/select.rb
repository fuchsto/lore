
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
Lore.disable_logging
Lore.disable_query_log

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

range_from = 1000
range_to   = 1100

module AR
  class Content < ActiveRecord::Base
  end

  class Article < ActiveRecord::Base
     belongs_to :content
  end
end

module Lore
  class Content < Lore::Model
    table :contents, :public
    primary_key :id, :content_id_seq
  end

  class Article < Lore::Model
    table :articles, :public
    primary_key :id, :article_id_seq
#   is_a Content, :content_id
  end

  Article.prepare(:id_in_range, Lore::Type.integer, Lore::Type.integer) { |a|
    a.where(Article.id.between('$1', '$2'))
    a.limit(100)
  }

end

num_loops   = ARGV[0].to_i
num_loops   = 100 if num_loops == 0

  class Result_Parser
  # {{{
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

  end # }}}

  # SQL raw definitions
  # {{{
db_name    = 'artest'
connection = PGconn.connect(Lore.pg_server, Lore.pg_port, '', '', db_name.to_s, Lore.user_for(db_name), Lore.pass_for(db_name.to_s))

sql = "SELECT * 
        FROM public.articles
        JOIN public.contents on (public.contents.id = public.articles.content_id)
        WHERE public.articles.id BETWEEN #{range_from} AND #{range_to} LIMIT #{range_to-range_from} OFFSET 0"

sql_exec = "EXECUTE public_articles__id_in_range(#{range_from},#{range_to}); "

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

    # }}}

(0..3000).to_a.each { |i|
# Lore::Article.create(:title   => "title_#{i}", 
#                      :tags    => [ :foo, :bar, :wombat ], 
#                      :text     => "text #{i}")
}


bmbm(12) { |test|
  test.report("unprocessed query") { 
    num_loops.times { 
      result = connection.exec(sql)
    }
  }
#  test.report("row parsing") { 
#    num_loops.times { 
#      result = connection.exec(sql)
#      p = Result_Parser.new(result)
#      p.get_rows
#    }
#  }
  test.report("result fetching in lore") { 
    num_loops.times { 
      result = connection.exec(sql)
      result = Lore::Result.new('',result)
      result.get_rows.each { |row|
        # noop
      }
    }
  }
  test.report("result parsing in lore") { 
    num_loops.times { 
      result = connection.exec(sql)
      result = Lore::Connection.perform(sql)
      result.get_rows.each { |row|
        # noop
      }
    }
  }
  test.report("ac_instances unfiltered") { 
    Lore.disable_cache
    Lore::Article.disable_output_filters if Lore::Article.respond_to?(:disable_output_filters)
    num_loops.times { 
      result = Lore::Connection.perform(sql).get_rows()
      result.map! { |row|
        row = (Lore::Article.new(row))
      }
    }
  }
  test.report("ac_instances filtered") { 
    Lore.disable_cache
    Lore::Article.enable_output_filters if Lore::Article.respond_to?(:enable_output_filters)
    num_loops.times { 
      result = Lore::Connection.perform(sql).get_rows()
      result.map! { |row|
        row = (Lore::Article.new(row))
      }
    }
  }
  test.report("lore select unfiltered") { 
    Lore.disable_cache
    Lore::Article.disable_output_filters if Lore::Article.respond_to?(:disable_output_filters)
    id_error = false
    count = 0
    num_loops.times { 
      count = range_from
      Lore::Article.select { |a|
        a.where(Lore::Article.id.in(range_from..range_to))
        a.limit(100)
      }.each { |a|
        raise ::Exception.new("ID ERROR: #{a.id.inspect} != #{count.inspect}") if a.id.to_s != count.to_s
        count += 1
      }
    }
  }
  test.report("lore shortcut filtered") { 
    id_error = false
    Lore.disable_cache
    Lore::Article.enable_output_filters if Lore::Article.respond_to?(:enable_output_filters)
    count = 0
    num_loops.times { 
      count = range_from
      r = Lore::Article.find(:all).with(Lore::Article.id.in(range_from..range_to)).each { |a|
        # raise ::Exception.new("ID ERROR: #{a.id.inspect} != #{count.inspect}") if a.id != count
        count += 1
        valid = true
        valid = valid && a.tags.is_a?(Array)
        valid = valid && a.id.is_a?(Fixnum)
        # raise ::Exception.new("TYPE ERROR") unless valid
      }
    }
  }
  test.report("lore shortcut unfiltered") { 
    id_error = false
    Lore.disable_cache
    Lore::Article.disable_output_filters if Lore::Article.respond_to?(:disable_output_filters)
    count = 0
    num_loops.times { 
      count = range_from
      r = Lore::Article.find(:all).with(Lore::Article.id.in(range_from..range_to)).each { |a|
        # raise ::Exception.new("ID ERROR: #{a.id.inspect} != #{count.inspect}") if a.id != count
        count += 1
        valid = true
        valid = valid && a.tags.is_a?(Array)
        valid = valid && a.id.is_a?(Fixnum)
        # raise ::Exception.new("TYPE ERROR") unless valid
      }
    }
  }
  test.report("activerecord") { 
    id_error = false
    count = 0
    num_loops.times { 
      count = range_from
      for a in AR::Article.find(:all, :include => :content, :conditions => "id between #{range_from} AND #{range_to}") do
        # raise ::Exception.new("ID ERROR: #{a.id.inspect} != #{count.inspect}") if a.id != count
        count += 1
        valid = true
        valid = valid && a.tags.is_a?(Array)
        valid = valid && a.id.is_a?(Fixnum)
        # raise ::Exception.new("TYPE ERROR") unless valid
      end
    }
  }
  test.report('lore using cache') { 
    id_error = false
    Lore.enable_cache
    Lore::Article.disable_output_filters if Lore::Article.respond_to?(:disable_output_filters)
    count = 0
    num_loops.times { 
      count = range_from
      Lore::Article.find(100).with(Lore::Article.id.in(range_from..range_to)).each { |a|
        # raise ::Exception.new("ID ERROR: #{a.id.inspect} != #{count.inspect}") if a.id != count
        count += 1
        valid = true
        valid = valid && a.tags.is_a?(Array)
        valid = valid && a.id.is_a?(Fixnum)
        # raise ::Exception.new("TYPE ERROR") unless valid
      }
    }
  }
  test.report("lore prepared") { 
    id_error = false
    Lore.disable_cache
    count = 0
    num_loops.times { 
      count = range_from
      Lore::Article.id_in_range(range_from,range_to).each { |a|
        # raise ::Exception.new("ID ERROR: #{a.id.inspect} != #{count.inspect}") if a.id != count
        count += 1
        valid = true
        valid = valid && a.tags.is_a?(Array)
        valid = valid && a.id.is_a?(Fixnum)
        # raise ::Exception.new("TYPE ERROR") unless valid
      }
    }
  }
}


