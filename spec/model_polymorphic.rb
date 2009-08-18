
require 'spec_env'
include Lore::Spec_Fixtures::Polymorphic_Models

describe(Lore::Table_Accessor) do
  before do
    flush_test_data()
  end

  it "implements the Liskov substitution principle" do
  end

  it "implements inverse polymorphism" do

    Asset.__associations__.concrete_models.length.should == 2

    expected = { 'public.asset' => :model }
    Media_Asset.__associations__.polymorphics.should_be expected

    media = Media_Asset.create(:folder     => '/tmp/spec/media/', 
                               :filename   => 'music.ogg', 
                               :media_type => 'sound')
    docum = Document_Asset.create(:folder   => '/tmp/spec/docs/', 
                                  :filename => 'sample.txt', 
                                  :doctype  => 'plaintext')
    media_polymorphic_id = media.asset_id
    docum_polymorphic_id = docum.asset_id

    asset = Asset.select_polymorphic { |a|
      a.where(:asset_id.is media_polymorphic_id)
      a.limit(1)
    }.first
    asset.is_a?(Media_Asset).should == true
    asset.is_a?(Asset).should == true
    asset.media_type.should == 'sound'

    asset = Asset.select_polymorphic { |a|
      a.where(:asset_id.is docum_polymorphic_id)
      a.limit(1)
    }.first
    asset.is_a?(Document_Asset).should == true
    asset.is_a?(Asset).should == true
    asset.doctype.should == 'plaintext'
  end

end
