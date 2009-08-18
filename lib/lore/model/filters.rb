
module Lore

  class Filters

    attr_accessor :input_filters, :output_filters

    def initialize(accessor)
      @accessor = accessor
      @input_filters  = {}
      @output_filters = {}
    end

    def inherit(base_model)
      parent_filters = base_model.__filters__
      @input_filters.update(parent_filters.input_filters.dup)
      @output_filters.update(parent_filters.output_filters.dup)
    end

    def add_input_filter(attr_name, &block)
      # Filters are mapped to attribute names disregarding their 
      # original table. 
      @input_filters[attr_name.to_sym] = block
    end

    def add_output_filter(attr_name, &block)
      # Filters are mapped to attribute names disregarding their 
      # original table. 
      @output_filters[attr_name.to_sym] = block
    end

  end

end
