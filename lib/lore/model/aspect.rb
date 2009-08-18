

module Lore

  # Steps taken in .create are: 
  # 
  # * .before_create(attribs)
  # * applying input filters
  # * .before_create_after_filters(attribs)
  # * distributing attributes to tables: 
  #    { :attrib => 'value' } -> { 'public.my_table' => { :attrib => 'value'} }
  # * .before_create_and_validation(table_attribs)
  # * validation
  # * .before_insert(table_attribs)
  # * insert operation
  # * .before_load(attribs)
  # * load new instance from DB (thus getting final table values)
  # * .after_create(created_instance)

  module Aspect

  private

    def before_delete(args)
    end

    def after_delete(args)
    end

    # Expects arguments (value hash) passed
    # to Table_Accessor.create
    def before_create(args)
    end

    # Expects arguments (value hash) passed
    # to Table_Accessor.create
    def after_filters(filtered_args)
    end

    # Expects arguments (value hash) passed
    # to Table_Accessor.create and distributed 
    # to table names
    def before_validation(distributed_args)
    end

    # Expects arguments (value hash) passed
    # to Table_Accessor.create and distributed 
    # to table names
    def before_insert(validated_args)
    end

    def before_load(completed_args)
    end

    # Expects object that has been created. 
    def after_create(obj)
    end

  public
    
    # Expects model instance to be deleted. 
    def before_instance_delete(model_instance)
    end
    # Expects model instance table rows have been 
    # deleted of
    def after_instance_delete(model_instance)
    end

    # Expects arguments (value hash) passed
    # to Table_Accessor.create and object 
    # to be updated. 
    def before_commit(obj)
    end
    # Expects updated object. 
    def after_commit(obj)
    end

  end

end
