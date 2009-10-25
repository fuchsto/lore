
require 'lore/model'

module Lore
module Spec_Fixtures
module Polymorphic_Models

  class Asset < Lore::Model

    table :asset, :public
    primary_key :asset_id, :asset_id_seq

    expects :folder, :filename

    is_polymorphic :model

    def path
      folder + '/' + filename
    end
  end

  class Container < Lore::Model
    table :container, :public
    primary_key :container_id, :container_id_seq

    expects :position
  end

  class Media_Asset_Info < Lore::Model
    table :media_asset_info, :public
    primary_key :id, :media_asset_id_seq
    expects :media_asset_id
  end

  class Document_Asset_Info < Lore::Model
    table :document_asset_info, :public
    primary_key :id, :document_asset_id_seq
    expects :document_asset_id
  end

  class Media_Asset < Asset
    table :media_asset, :public
    primary_key :id, :media_asset_id_seq

    is_a Asset, :asset_id

    expects :media_type
    aggregates Media_Asset_Info, :info_id
  end

# class Movie_Asset < Media_Asset
#   table :movie_asset, :public
#   primary_key :id, :movie_asset_id_seq
#
#   is_a Media_Asset, :media_asset_id
#
#   def self.before_create(args)
#     args[:media_type] = 'movie'
#   end
# end

  class Document_Asset < Asset
    table :document_asset, :public
    primary_key :id, :document_asset_id_seq

    is_a Asset, :asset_id
    is_a Container, :container_id

    expects :doctype
    aggregates Document_Asset_Info, :info_id
  end

end
end
end

