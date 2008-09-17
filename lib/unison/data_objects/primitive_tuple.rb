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
          raise ArgumentError, "Value #{value.inspect} is not Java-compatible"
        end
      end

      def get(key)
        raise ArgumentError, "Attribute name must be a String" unless key.instance_of?(String)
        attribute_values[key]
      end

      def attributeNameIterator
        Iterator.new(attribute_values.keys)
      end

      class Iterator
        def initialize(items)
          @items = items
          @index = 0
        end

        def hasNext
          index < items.size
        end

        def next
          raise "Out of bounds" unless hasNext
          item = items[index]
          @index += 1
          item
        end

        protected
        attr_reader :items, :index
      end

      protected
      attr_reader :attribute_values
    end
  end
end