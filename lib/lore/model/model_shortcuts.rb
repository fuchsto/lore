
module Lore

  module Model_Shortcuts

    def html_escape_values_of(*attributes)
      add_input_filter(*attributes) { |a|
        a = a.to_s
        a.gsub("'",'&apos;')
        a.gsub('"','&quot;')
      }
      add_output_filter(*attributes) { |a|
        a = a.to_s
        a.gsub("'",'&apos;')
        a.gsub('"','&quot;')
      }
    end
    alias html_encode html_escape_values_of

    def convert_decimal(*attributes)
      add_input_filter(*attributes) { |v|
        v.gsub!(/\s/,'')
        v.sub!(',','.')
        v = "0.00" if v == ''
        v = "#{v}.00" if !v.include?('.') 
        v
      }
      add_output_filter(*attributes) { |v|
        v.sub('.',',')
      }
    end

  end

end
