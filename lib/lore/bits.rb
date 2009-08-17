
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
end

class String
  def empty? 
    return self == ''
  end
end

class Nil
  def empty?
    true
  end
end
