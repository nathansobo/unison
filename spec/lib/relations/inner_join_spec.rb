require "#{File.dirname(__FILE__)}/../../spec_helper"

module Unison
  module Relations
    describe InnerJoin do
      attr_reader :join
      before do
        @join = InnerJoin.new(users_set, photos_set, photos_set[:user_id].eq(users_set[:id]))
      end

      describe "#initialize" do
        it "sets #operand_1, #operand_2, and #predicate" do
          join.operand_1.should == users_set
          join.operand_2.should == photos_set
          join.predicate.should == photos_set[:user_id].eq(users_set[:id])
        end
      end
    end
  end
end
