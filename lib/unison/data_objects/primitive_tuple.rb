module Unison
  module DataObjects
    class PrimitiveTuple

      def initialize
        @attribute_values = {}
      end

      def put(key, value)
        raise ArgumentError, "Attribute name must be a String" unless key.instance_of?(String)
        case value
        when Fixnum, String, TrueClass, FalseClass, NilClass
          attribute_values[key] = value
        else
          raise ArgumentError, "Value type must be Java-compatible"
        end
      end

      def get(key)
        raise ArgumentError, "Attribute name must be a String" unless key.instance_of?(String)
        attribute_values[key]
      end

      def attributeIterator
        AttributeIterator.new(attribute_values)
      end

      class AttributeIterator
        def initialize(attribute_values)
          @entries = attribute_values.inject([]) do |entries, entry|
            entries + [entry]
          end
          @index = 0
        end

        def hasNext
          index < entries.size
        end

        def next
          raise "Out of bounds" unless hasNext
          @index += 1
        end

        def name
          entries[index][0]
        end

        def value
          entries[index][1]
        end

        protected
        attr_reader :entries, :index
      end

      protected
      attr_reader :attribute_values
    end
  end
end