module Unison
  module Attributes
    class Attribute
      attr_reader :set, :name

      def initialize(set, name)
        @set, @name = set, name
      end
    end
  end
end