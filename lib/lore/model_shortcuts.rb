
module Lore

  module Model_Shortcuts

    def html_escape_values_of(*attributes)
      attributes.each { |attrib|
        add_input_filter(attrib) { |a|
          a = a.to_s
          a.gsub("'",'&apos;')
          a.gsub("\"",'&quot;')
        }
        add_output_filter(attrib) { |a|
          a = a.to_s
          a.gsub("'",'&apos;')
          a.gsub("\"",'&quot;')
        }
      }
    end

  end

end
