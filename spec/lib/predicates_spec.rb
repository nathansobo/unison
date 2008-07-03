require "#{File.dirname(__FILE__)}/../spec_helper"

module Unison
  module Predicates
    describe Eq do
      attr_reader :predicate
      
      before do
        @predicate = Eq.new(users_set[:name], "Nathan")
      end

      describe "#call" do
        it "returns true if one of the operands is an attribute and its value in the tuple =='s the other operand" do
          predicate.call(User.new(:id => 1, :name => "Nathan")).should be_true
        end

        it "returns false if one of the operands is an attribute and its value in the tuple doesn't == the other operand" do
          predicate.call(User.new(:id => 1, :name => "Corey")).should be_false
        end
        
        it "returns true if its operands are == when called on any tuple" do
          predicate = Eq.new(1, 1)
          predicate.call(User.new(:id => 1, :name => "Nathan")).should be_true
        end
      end

      describe "#==" do
        it "returns true for Eq predicates with == operands and false otherwise" do
          predicate.should == Eq.new(users_set[:name], "Nathan")
          predicate.should_not == Eq.new(users_set[:id], "Nathan")
          predicate.should_not == Eq.new(users_set[:name], "Corey")
          predicate.should_not == Object.new
        end
      end
    end
  end
end