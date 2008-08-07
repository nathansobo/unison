module Unison
  module Adapters
    module Arel
      class Engine
        attr_reader :set
        def initialize(set)
          @set = set
        end
        
        def columns(*args)
          set.attributes.values
        end

        def quote_table_name(name)
          quote_column_name(name)
        end

        def quote_column_name(name)
          "`#{name}`"
        end

        include Quoting
      end
    end
  end
end