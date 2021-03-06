module Arel
  module Sql
    class Christener
      def name_for(relation)
        @used_names ||= Hash.new(0)
        (@relation_names ||= Hash.new do |hash, relation|
          @used_names[name = relation.name] += 1
          hash[relation] = name + (@used_names[name] > 1 ? "_#{@used_names[name]}" : '')
        end)[relation.table]
      end
    end
  end
end