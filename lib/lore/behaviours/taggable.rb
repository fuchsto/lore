

module Lore

	class Refined_Select < Lore::Refined_Query
    # Helper method for taggable models. 
    # Extends Lore::Clause by select helper #by_tag. 
    # Usage: 
    #
    #    Article.find(10).by_tag('foo', 'bar').with(your_constraints).entities
    #
		def by_tag(*tags)
      tags = tags.first if tags.first.is_a?(Array)
			constraints = Lore::Clause.new('')
			tags.each { |k|
				constraints = constraints & (@accessor.tags.has_element_ilike(k))
			}
			key = tags.join(' ')
			with(constraints)
		end
		alias with_tag by_tag

	end # class

  # Usage: Extend Lore::Model with this helper module. 
  # Usage: 
  #
  #   Some_Content.find(10).with(Some_Content.has_tag('foo%')),entities
  # Or
  #   Some_Content.find(10).with(Some_Content.has_tags('foo%', '%bar', 'batz')),entities
  #
  # This helper also considers tag synonyms (see Tag_Synonym). 
  #
  module Taggable_Behaviour
    def has_tag(*tags)
      tags = tags.first if tags.first.is_a?(Array)
			constraints = Lore::Clause.new('')
			tags.each { |k|
        constraints = constraints & (self.tags.has_element_ilike(k))
			}
      constraints
    end
    alias has_tags has_tag

    # Shortcut for
    #
    #   find(:all).by_tag(*tags)
    #
    # See Lore::Refined_Select.by_tag
    def all_by_tag(*tags)
      find(:all).by_tag(*tags)
    end

  end

end

