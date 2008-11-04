require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Predicates
    describe NotEqualTo do
      attr_reader :predicate, :operand_1, :operand_2

      before do
        @operand_1 = users_set[:name]
        @operand_2 = "Nathan"
        @predicate = NotEqualTo.new(operand_1, operand_2)
      end

      describe "#fetch_arel" do
        it "returns an Arel::Where representation" do
          predicate.fetch_arel.should == Arel::Inequality.new(operand_1.fetch_arel, operand_2.fetch_arel)
        end
      end

      describe "#eval" do
        it "returns false if one of the operands is an attribute and its value in the tuple =='s the other operand" do
          predicate.eval(User.new(:id => 1, :name => "Nathan")).should be_false
        end

        it "returns true if one of the operands is an attribute and its value in the tuple doesn't == the other operand" do
          predicate.eval(User.new(:id => 1, :name => "Corey")).should be_true
        end

        it "returns false if its operands are == when called on any tuple" do
          predicate = NotEqualTo.new(1, 1)
          predicate.eval(User.new(:id => 1, :name => "Nathan")).should be_false
        end
      end
    end
  end
end