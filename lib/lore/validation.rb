

module Lore
module Validation

    
  def validates(attrib, constraints)
  # {{{
    if attrib.kind_of? Clause then
      attrib_split = attrib.to_s.split('.')
      table = attrib_split[0..-2]
      attrib = attrib_split[-1]
    else
      table = get_table_name
    end
    attrib = attrib.intern unless attrib.instance_of? Symbol

    @constraints = Hash.new if @constraints.nil?
    @constraints[table] = Hash.new if @constraints[table].nil?
    @constraints[table][attrib] = Hash.new

    if constraints[:mandatory] then
      add_explicit_attribute(table, attrib.to_s)
    end
    if constraints[:type] then
    # @attribute_types[table][attrib] = constraints[:type]
      @constraints[table][attrib][:type] = constraints[:type]
    end
    if constraints[:format] then
      @constraints[table][attrib][:format] = constraints[:format]
    end
    if constraints[:length] then
      if constraints[:length].kind_of? Range then
        @constraints[table][attrib][:minlength] = constraints[:length].first
        @constraints[table][attrib][:maxlength] = constraints[:length].last
      else 
        @constraints[table][attrib][:minlength] = constraints[:length]
        @constraints[table][attrib][:maxlength] = constraints[:length]
      end
    end
    if constraints[:minlength] then
      @constraints[table][attrib][:minlength] = constraints[:minlength]
    end
    if constraints[:maxlength] then
      @constraints[table][attrib][:maxlength] = constraints[:maxlength]
    end
  end # }}}


  def get_constraints
  # {{{

    @constraints = Hash.new if @constraints.nil?
    if !@is_a_klasses.nil? then
      @is_a_klasses.each_pair { |foreign_key, klass|
        @constraints.update(klass.get_constraints)
      }
    end
    @constraints

  end # }}}

  
end 
end
