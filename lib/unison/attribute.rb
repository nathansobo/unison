module Unison
  class Attribute
    module PredicateConstructors
      def eq(other)
        Predicates::EqualTo.new(self, other)
      end
    end
    include PredicateConstructors

    attr_reader :relation, :name, :type

    VALID_TYPES = [:integer, :boolean, :string, :symbol, :datetime]

    def initialize(relation, name, type)
      raise ArgumentError, "Type #{type.inspect} is invalid. Valid types are #{VALID_TYPES.inspect}" unless VALID_TYPES.include?(type)
      @relation, @name, @type = relation, name, type
    end

    def convert(value)
      send("convert_to_#{type}", value)
    end

    def ==(other)
      return false unless other.instance_of?(Attribute)
      relation.equal?(other.relation) && name == other.name
    end

    def to_arel
      relation.to_arel[name]
    end

    protected
    def convert_to_integer(value)
      Integer(value)
    end

    def convert_to_boolean(value)
      case value
      when 'false', false
        false
      when 'true', true
        true
      when nil
        nil
      else
        raise ArgumentError, "#{value.inspect} is not a valid representation of a boolean"
      end
    end

    def convert_to_symbol(value)
      case value
      when Symbol
        value
      else
        value.to_s.to_sym
      end
    end
    
    def convert_to_string(value)
      value.to_s
    end

    def convert_to_datetime(value)
      case value
      when Time
        utc_time = value.utc
        Time.utc(
          utc_time.year,
          utc_time.month,
          utc_time.day,
          utc_time.hour,
          utc_time.min,
          utc_time.sec
        )
      when Integer
        Time.at(value)
      when String
        time_values = Time.parse(value)
        Time.utc(
          time_values.year,
          time_values.month,
          time_values.day,
          time_values.hour,
          time_values.min,
          time_values.sec
        )
      end
    end
  end
end