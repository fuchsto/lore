
require('postgres')
require('digest/md5')

module Lore
  
class Result # :nodoc:

  attr_reader :query_hashval, :field_names, :field_types

  # expects PGresult
  def initialize(query, result) 
    @result = result
    @field_types      = nil
    @result_rows      = Array.new
    @num_fields       = @result.num_fields
    @num_tuples       = @result.num_tuples
    @field_counter    = 0
    @field_names      = @result.fields
  end # def initialize
  
  def get_field_value(row_index, field_name)
    field_index = @result.fieldnum(field_name)
    return @result.getvalue(row_index, field_index)
  end # def get_field_value
  
  def get_field_types()
    
    return @field_types unless @field_types.nil?
    
    @field_types = Hash.new
    for field_index in 0...get_field_num()
      @field_types[@result.fields[field_index]] = @result.type(field_index)
    end
    
    return @field_types
  end
  alias field_types get_field_types
  alias get_field_names field_names
  
  def get_field_num()
    @num_fields
  end
  
  def get_tuple_num()
    @result.num_tuples
  end
  
  def get_row(row_num=0)
    @result[row_num]
  end
  def get_row_with_field_names(row_num=0)

    return if @result.num_tuples == 0

    row_result = Array.new
    
    @field_counter = 0
    for @field_counter in 0...@num_fields do
      row_result << @result.getvalue(row_num, @field_counter)
    end
    @fieldnames = []
    for @field_counter in 0...@num_fields do
      @fieldnames << @result.fieldname(@field_counter)
    end
    return { :values => row_result, :fields => @fieldnames }
    
  end
  
  def get_rows()
    rows = []
    for tuple_count in 0...@result.num_tuples do
      rows << @result[tuple_count]
    end

    # return { :values => rows, :fields => @fields }
    return rows
  end
  
  def fieldname(index)
    return @result.fieldname(index)
  end
  
end # class Result

end # module Lore
