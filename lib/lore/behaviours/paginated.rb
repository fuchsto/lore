
module Lore
module Behaviours


  # Usage: 
  #
  #   class My_Model < Lore::Model
  #   extend Lore::Behaviours::Paginated
  #   
  #     def self.search(search, page)
  #       paginate(:per_page => 10, 
  #                :page => page, 
  #                :filter => all_with(search).order_by(:name, :desc))
  #     end
  #
  #   end
  #
  #   first_page_entities => My_Model.search((My_Model.attribute == 'foo'), 1)
  #
  module Paginated
  
    def paginate(params)
      entities = params[:filter].limit(params[:per_page], params[:page]).entities
    end
  
  end

end
end

