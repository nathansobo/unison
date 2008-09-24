module Unison
  class Attribute
    module PredicateConstructors
      def eq(other)
        Predicates::EqualTo.new(self, other)
      end

      def neq(other)
        Predicates::NotEqualTo.new(self, other)
      end

      def gt(other)
        Predicates::GreaterThan.new(self, other)
      end

      def lt(other)
        Predicates::LessThan.new(self, other)
      end

      def gteq(other)
        Predicates::GreaterThanOrEqualTo.new(self, other)
      end

      def lteq(other)
        Predicates::LessThanOrEqualTo.new(self, other)
      end
    end
    include PredicateConstructors

    attr_reader :set, :name, :type, :transform

    VALID_TYPES = [:integer, :boolean, :string, :symbol, :datetime, :object]

    def initialize(set, name, type, &transform)
      raise ArgumentError, "Type #{type.inspect} is invalid. Valid types are #{VALID_TYPES.inspect}" unless VALID_TYPES.include?(type)
      @set, @name, @type, @transform = set, name, type, transform
      @ascending = true
    end

    def convert(value)
      value.nil?? nil : send("convert_to_#{type}", value)
    rescue Exception => e
      e.message.replace("Error converting value for '#{set.name}.#{name}' attribute\n#{e.message}")
      raise e
    end

    def ascending
      @ascending = true
      self
    end

    def ascending?
      @ascending == true
    end

    def descending
      @ascending = false
      self
    end

    def descending?
      !ascending?
    end

    def ==(other)
      return false unless other.instance_of?(Attribute)
      set.equal?(other.set) && name == other.name && transform == other.transform
    end

    def to_arel
      set.to_arel[name]
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
        value
      when Integer
        Time.at(value).utc
      when String
        local_time = Time.parse(value)
        Time.utc(
          local_time.year,
          local_time.month,
          local_time.day,
          local_time.hour,
          local_time.min,
          local_time.sec,
          local_time.usec
        )
      end
    end

    def convert_to_object(value)
      value
    end
  end
end