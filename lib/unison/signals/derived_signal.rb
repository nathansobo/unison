module Unison
  module Signals
    class DerivedSignal < Signal
      retain :source
      subscribe do
        source.on_change do |source_old_value, source_new_value|
          old_value = @value || apply_transform(source_old_value)
          @value = apply_transform(source_new_value)
          change_subscription_node.call(old_value, value) unless old_value == value
        end
      end

      attr_reader :source, :method_name, :transform
      def initialize(source, method_name = nil, &transform)
        super()
        @source, @method_name, @transform = source, method_name, transform
      end

      def value
        @value ||= transform.call(source.value)
      end

      protected
      def apply_transform(value)
        value = value.send(method_name) if method_name
        value = transform.call(value) if transform
        value
      end
    end
  end
end
