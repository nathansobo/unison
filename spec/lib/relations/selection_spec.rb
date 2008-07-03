require "#{File.dirname(__FILE__)}/../../spec_helper"

module Unison
  module Relations
    describe Selection do
      attr_reader :selection
      before do
        @selection = Selection.new(photos_set, photos_set[:user_id].eq(1))
      end

      describe "#initialize" do
        it "sets the #operand and #predicate" do
          selection.operand.should == photos_set
          selection.predicate.should == photos_set[:user_id].eq(1)
        end
      end

      describe "#read" do
        it "returns all tuples in its operand for which its predicate returns true" do
          tuples = selection.read
          tuples.size.should == 2
          tuples.each do |tuple|
            tuple[:user_id].should == 1
          end
        end
      end
    end
  end
end