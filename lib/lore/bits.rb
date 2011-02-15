
module Lore

  def self.resolve_passed_value(values, table_name, attrib_name)
    return { :value => values[attrib_name].to_s, :field => attrib_name }
    idx = attrib_name.to_s.length
    value = nil
    while value.nil? && idx > 1 do 
      name_part = attrib_name.to_s[0..idx]
      value = values[name_part]
      if value == '' then 
        name_part = table_name + '.' << name_part
        value = values[name_part]
      end

      idx -= 1
    end
    { :value => value, :field => name_part }
  end

end

class Hash

  def deep_merge!(second)
    merger = proc { |key,v1,v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    self.merge!(second, &merger)
  end
  
  def nested_hash(array)
    node = self
    array.each do |i|
       node[i]=Hash.new if node[i].nil?
       node = node[i]
    end 
    self
  end
  
  def merge_nested_hash!(nested_hash)
    deep_merge!(nested_hash)
  end
  
  def keys_flat(keys_result=[])
    keys.each { |k|
     keys_result << k
     child = self[k]
     child.keys_flat(keys_result) if (child && child.kind_of?(Hash))
    } 
    return keys_result
  end

end

class Object
  def empty? 
    false
  end

  def db_escaped?
    false
  end
end

class String

  attr_reader :db_escaped

  def empty? 
    return self == ''
  end

  def db_escaped!
    @db_escaped = true
    return self
  end

  def db_escaped?
    @db_escaped || false
  end
end

class Nil
  def empty?
    true
  end
end

class With_Builder 

  def initialize(obj, &block)
    @obj = obj
    instance_eval(&block)
  end

  def method_missing(meth, *args)
    @obj.__send__(meth, *args)
  end

end

module Kernel

  # Implementation of a generic with(obj) Syntax. 
  # Usage: 
  #
  #   a = [ 1,2,3,4 ]
  #
  #   with(a) { 
  #     push 'b'
  #     push 'c'
  #   }
  #
  #   p a 
  #   --> [ 1,2,3,4,'b','c']
  # 
  # Combined with method chaining, this enables a 
  # DSL for queries like: 
  #
  #   User.find(1).with(User.username.like 'foo').offset(3)
  #   
  # to be written as: 
  #
  #   with(User.find(1)) { 
  #     sort_by :username, :asc
  #     with User.username.like 'foo'
  #     offset 3
  #   }
  # 
  def with(obj, &block)
    With_Builder.new(obj, &block)
  end

end

