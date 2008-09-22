module Unison
  module Signals
    class SingletonRelationSignal < Signal
      attr_reader :value
      retain :value
      
      def initialize(value)
        raise(ArgumentError, "#value must be an instance of SingletonRelation") unless value.is_a?(Relations::SingletonRelation)
        super()
        @value = value
      end

      def ==(other)
        other.is_a?(SingletonRelationSignal) && other.value == value
      end
    end
  end
end
