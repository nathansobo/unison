module Unison
  module Attributes
    class PrimitiveAttribute < Attribute
      attr_reader :type, :transform, :default

      VALID_TYPES = [:integer, :boolean, :string, :symbol, :datetime, :object]

      def initialize(set, name, type, options={}, &transform)
        raise ArgumentError, "Type #{type.inspect} is invalid. Valid types are #{VALID_TYPES.inspect}" unless VALID_TYPES.include?(type)
        super(set, name)
        @type, @transform = type, transform
        @ascending = true
        if name == :id && !options.has_key?(:default)
          @default = lambda { Guid.new.to_s }
        else
          @default = options[:default]
        end
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
        return false unless other.instance_of?(PrimitiveAttribute)
        set.equal?(other.set) && name == other.name && transform == other.transform
      end

      def to_arel
        set.to_arel[name]
      end

      def create_field(tuple)
        PrimitiveField.new(tuple, self)
      end

      def inspect
        "#{set.inspect}[#{name.inspect}]"
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
end