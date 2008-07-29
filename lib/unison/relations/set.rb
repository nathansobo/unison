module Unison
  module Relations
    class Set < Relation
      attr_reader :name, :attributes, :tuples

      def initialize(name)
        super()
        @name = name
        @attributes = []
        @tuples = []
      end

      def tuple_superclass
        Tuple::Base
      end

      def attribute(name)
        attributes.push(Attribute.new(self, name))
      end

      def has_attribute?(attribute)
        case attribute
        when Attribute
          attributes.include?(attribute)
        when Symbol
          !self[attribute].nil?
        end
      end

      def [](attribute_name)
        attributes.detect {|attribute| attribute.name == attribute_name}
      end

      def insert(tuple)
        tuples.push(tuple)
        insert_subscriptions.each do |proc|
          proc.call(tuple)
        end
        tuple
      end

      def read
        tuples
      end

      def each(&block)
        tuples.each(&block)
      end

      protected
    end
  end
end