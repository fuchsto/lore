
require('postgres-pr/connection')

module Lore

class Result 

  attr_reader :query_hashval, :field_names, :field_types

  # expects PostgresPR::Result
  def initialize(query, result) 
    @result           = result
    @field_types      = {}
    @result.fields.each { |f| 
      @field_types[f.name] = f.type_oid 
    }
    @num_fields       = @result.fields.length
    @num_tuples       = @result.rows.length
    @field_names      = @result.fields.map { |f| f.name }
  end 
  
  def get_field_value(row_index, field_name)
    # TODO: Optimize this! 
    field_index = 0
    @result.fields.each { |f| 
      break if f.name == field_name 
      field_index += 1
    }
    return @result.rows[row_index][field_index]
  end 
  
  def get_field_types()
    return @field_types
  end
  alias field_types get_field_types
  alias get_field_names field_names
  
  def get_field_num()
    @num_fields
  end
  
  def get_tuple_num()
    @num_tuples
  end
  
  def get_row(row_num=0)
    @result.rows[row_num]
  end
  def get_row_with_field_names(row_num=0)
    return { :values => @result.rows, :fields => @result.fields }
  end
  
  def get_rows()
    return @result.rows
  end
  
  def fieldname(index)
    return @fields_names[index]
  end
  
end # class Result

end # module Lore
