module Unison
  module Tuples
    class Topic < PrimitiveTuple
      class << self
        def expose(*names)
          exposed_method_names.concat(names)
        end

        protected
        def exposed_method_names
          @exposed_method_names ||= []
        end
      end

      retain :exposed_objects

      attr_reader :subject
      def initialize(subject)
        @subject = subject
        super()
      end

      def exposed_objects
        self.class.send(:exposed_method_names).map do |name|
          self.send(name)
        end
      end

      def to_hash
        
      end

      protected
      def method_missing(method_name, *args, &block)
        subject.send(method_name, *args, &block)
      rescue NoMethodError => e
        e.message.replace("undefined method `#{method_name}' for #{inspect}")
        raise e
      end
    end
  end
end
