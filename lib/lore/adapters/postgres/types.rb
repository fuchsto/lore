
module Lore

  PG_BOOL                = 16
  PG_BYTEA               = 17
  PG_SMALLINT            = 21
  PG_CHAR                = 18
  PG_INT                 = 23
  PG_TEXT                = 25
  PG_FLOAT               = 701
  PG_INT_LIST            = 1007
  PG_CHARACTER           = 1042
  PG_VARCHAR             = 1043
  PG_TIME                = 1083
  PG_TIMESTAMP_TIMEZONE  = 1184
  PG_TIMESTAMP           = 1114
  PG_DATE                = 1082
  PG_VCHAR_LIST          = 1015
  PG_DECIMAL             = 1700

  TYPE_NAMES = { 
    PG_BYTEA               => 'bytea',
    PG_BOOL                => 'boolean',
    PG_SMALLINT            => 'small int',
    PG_CHAR                => 'char',
    PG_INT                 => 'integer',
    PG_INT_LIST            => 'integer[]',
    PG_TEXT                => 'text',
    PG_FLOAT               => 'float', 
    PG_CHARACTER           => 'character',
    PG_VARCHAR             => 'character varying(1000)',
    PG_TIME                => 'time',
    PG_TIMESTAMP_TIMEZONE  => 'timestamp with timezone',
    PG_TIMESTAMP           => 'timestamp',
    PG_DATE                => 'data',
    PG_VCHAR_LIST          => 'character varying[]', 
    PG_DECIMAL             => 'decimal'
  }

  class Type

    def self.integer; 'integer'; end
    def self.integer_list; 'integer[]'; end
    def self.boolean; 'boolean'; end
    def self.bytea; 'bytea'; end
    def self.char; 'char'; end
    def self.varchar(length=255); 'character varying(' << length.to_s + ')'; end
    def self.varchar_list; 'varchar[]'; end
    def self.character(length=255); 'character(' << length.to_s + ')'; end
    def self.time; 'time'; end
    def self.timestamp; 'timestamp'; end
    def self.date; 'date'; end
    def self.text; 'text'; end
    def self.decimal; 'decimal'; end

    def self.type_name(int)
      TYPE_NAMES[int]
    end

  end

  class Type_Filters

    @@input_filters = { 
      PG_VCHAR_LIST          => lambda { |v| if (v.to_s.squeeze(' ').length == 0) then '{}' else "{#{v.join(',')}}" end }, 
      PG_INT_LIST            => lambda { |v| "{#{v.join(',')}}" }, 
      PG_BOOL                => lambda { |v| if (v && v != 'f' && v != 'false' || v == 't' || v == 'true') then 't' elsif (v.instance_of?(FalseClass) || v == 'f' || v == 'false') then 'f' else nil end }, 
      PG_DATE                => lambda { |v| v.to_s }, 
      PG_TIME                => lambda { |v| v.to_s }, 
      PG_TIMESTAMP_TIMEZONE  => lambda { |v| v.to_s }, 
      PG_TIMESTAMP           => lambda { |v| v.to_s }, 
    # PG_BOOL                => lambda { |v| if v == true then 't' elsif v == false then 'f' else v.to_s end }
    }
    @@output_filters = { 
      PG_VCHAR_LIST          => lambda { |v| v[1..-2].split(',') }, 
      PG_INT_LIST            => lambda { |v| v[1..-2].split(',') }, 
      PG_INT                 => lambda { |v| if v then v.to_i else nil end }, 
      PG_SMALLINT            => lambda { |v| if v then v.to_i else nil end },
      PG_FLOAT               => lambda { |v| if v && v.length > 0 then v.to_f else nil end }, 
      PG_DECIMAL             => lambda { |v| if v && v.length > 0 then v.to_f else nil end }, 
      PG_BOOL                => lambda { |v| if v == 't' then true elsif v == 'f' then false else nil end }
# SLOW!
#     PG_DATE                => lambda { |v| Date.parse(v) if v }, 
#     PG_TIME                => lambda { |v| Time.parse(v) if v }, 
#     PG_TIMESTAMP_TIMEZONE  => lambda { |v| DateTime.parse(v) if v }, 
#     PG_TIMESTAMP           => lambda { |v| DateTime.parse(v) if v }
    }

    def self.in
      @@input_filters
    end

    def self.out
      @@output_filters
    end

  end

end # module

