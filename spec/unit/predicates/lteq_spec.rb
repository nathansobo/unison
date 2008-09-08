require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Predicates
    describe Lteq do
      attr_reader :predicate, :operand_1, :operand_2

      before do
        @operand_1 = users_set[:id]
        @operand_2 = 2
        @predicate = Lteq.new(operand_1, operand_2)
      end      
      
      describe "#to_arel" do
        it "returns an Arel::Where representation" do
          predicate.to_arel.should == Arel::LessThanOrEqualTo.new(operand_1.to_arel, operand_2.to_arel)
        end
      end

      describe "#eval" do
        it "returns true if one of the operands is an attribute and its value in the tuple is <= than the other operand" do
          predicate.eval(User.new(:id => operand_2 + 1)).should be_false
          predicate.eval(User.new(:id => operand_2)).should be_true
          predicate.eval(User.new(:id => operand_2 - 1)).should be_true
        end
      end
    end
  end
end