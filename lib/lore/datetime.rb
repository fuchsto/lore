
require('lore/clause')

module Lore

  class Clause

    def millisecond(params={})
      extract(:millisecond, params)
    end
    def second(params={})
      extract(:second, params)
    end
    def minute(params={})
      extract(:minute, params)
    end
    def hour(params={})
      extract(:hour, params)
    end
    def day(params={})
      extract(:day, params)
    end
    def week(params={})
      extract(:week, params)
    end
    def month(params={})
      extract(:month, params)
    end
    def year(params={})
      extract(:year, params)
    end

    def extract(what, params={})
      as = ''
      if params[:as] then 
        as = " as #{params[:as]}"
      end
      @field_name = "extract(#{what} from #{@field_name})#{as}"
      return self
    end

  end # class Clause

end # module Lore
