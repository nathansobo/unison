require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Predicates
    describe Predicate do
      attr_reader :predicate

      describe "#initialize" do
        context "when not passed a block" do
          it "raises an ArgumentError" do
            lambda do
              Predicate.new
            end.should raise_error(ArgumentError)
          end
        end
      end

      describe "#eval" do
        before do
          @predicate = Predicate.new do |tuple|
            tuple.name == "Nathan"
          end
        end

        context "when the passed in Tuple causes the proc to evaluate to true" do
          it "returns true" do
            user = User.find(1)
            user.name.should == "Nathan"
            predicate.eval(user).should be_true
          end
        end

        context "when the passed in Tuple causes the proc to evaluate to false" do
          it "returns false" do
            user = User.find(2)
            user.name.should_not == "Nathan"
            predicate.eval(user).should be_false
          end
        end
      end

      describe "#==" do
        context "when other Predicate has the same Proc" do
          it "returns true" do
            proc = lambda {}
            Predicate.new(&proc).should == Predicate.new(&proc)
          end
        end

        context "when other Predicate does not have the same Proc" do
          it "returns false" do
            Predicate.new { 1==2 }.should_not == Predicate.new {true == true}
          end
        end
        
        context "when other is not a Predicate" do
          it "returns false" do
            Predicate.new {}.should_not == Eq.new(users_set[:name], "Nathan")
          end
        end
      end
    end
  end
end
