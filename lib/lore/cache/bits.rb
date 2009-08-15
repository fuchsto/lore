
module Lore
module Cache

    @@ignore_params = [ 'cb__model', 'cb__controller', 'cb__mode' ]
  
    def self.store_name(klass_name, controller, mode, keys)
      key_string = ''
      keys.each_pair { |name, value|
        key_string += '@@@'+name+'==' << value.to_s unless @@ignore_params.include? name
      }
      controller = '*' if controller == :all
      mode = '*'       if mode == :all
      
      store_name  = '/tmp/cb__cache__' << klass_name.to_s << '@@@' << controller.to_s << '@@@' << mode.to_s
      store_name += key_string unless key_string == ''

      return store_name
    end

end # module
end # module
