module Unison
  module Signals
    class AttributeSignal < Signal
      attr_reader :tuple, :attribute

      retain :tuple
      subscribe do
        tuple.on_update do |updated_attribute, old_value, new_value|
          if attribute == updated_attribute
            change_subscription_node.call(new_value)
          end
        end
      end

      def initialize(tuple, attribute)
        super()
        @tuple, @attribute = tuple, attribute
      end

      def value
        tuple[attribute]
      end

      def ==(other)
        return false unless other.is_a?(AttributeSignal)
        other.attribute == attribute && other.tuple == tuple
      end  
    end    
  end
end