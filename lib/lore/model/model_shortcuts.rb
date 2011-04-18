
module Lore

  module Model_Shortcuts

    def html_escape_values_of(*attributes)
      add_input_filter(*attributes) { |a|
        a = a.to_s
#       a.gsub!("'",'&apos;')
        a.gsub!('"','&quot;')
        a
      }
      add_output_filter(*attributes) { |a|
        a = a.to_s
#       a.gsub!("'",'&apos;')
        a.gsub!('"','&quot;')
        a
      }
    end
    alias html_encode html_escape_values_of

    def convert_decimal(*attributes)
      add_input_filter(*attributes) { |v|
        if v.is_a?(Float) then
          v.to_s
        else
          v = v.to_s.gsub(/\s/,'')
          v.sub!(',','.')
          if v == '' then
            v = "0.00" 
          else
            v = "#{v}.00" if !v.include?('.') 
          end
          v
        end
      }
    end

  end

end
