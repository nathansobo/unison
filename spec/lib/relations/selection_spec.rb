require "#{File.dirname(__FILE__)}/../../spec_helper"

module Unison
  module Relations
    describe Selection do
      attr_reader :selection
      before do
        @selection = Selection.new(users_set, users_set[:name].eq("Nathan"))
      end

      describe "#initialize" do
        it "sets the #operand and #predicate" do
          selection.operand.should == users_set
          selection.predicate.should == users_set[:name].eq("Nathan")
        end
      end

      describe "#read" do
        before do
          users_set.insert(user_class.new(:id => 1, :name => "Nathan"))
          users_set.insert(user_class.new(:id => 2, :name => "Nathan"))
          users_set.insert(user_class.new(:id => 3, :name => "Corey"))
        end

        it "returns all tuples in its operand for which its predicate returns true" do
          tuples = selection.read
          tuples.size.should == 2
          tuples.each do |tuple|
            tuple[:name].should == "Nathan"
          end
        end
      end
    end
  end
end