require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

module Unison
  module Relations
    describe Relation do
      describe "#where" do
        it "returns a Selection with self as its #operand and the given predicate as its #predicate" do
          selection = users_set.where(users_set[:id].eq(1))
          selection.should be_an_instance_of(Selection)
          selection.operand.should == users_set
          selection.predicate.should == users_set[:id].eq(1)
        end
      end

      describe "#first" do
        it "returns the first tuple from #read" do
          users_set.first.should == users_set.read.first
        end
      end

      describe "#on_insert" do
        context "when not passed a block" do
          attr_reader :relation
          before do
            @relation = users_set
          end

          it "raises an ArgumentError" do
            lambda do
              relation.on_insert
            end.should raise_error(ArgumentError)
          end
        end
      end

      describe "#on_remove" do
        context "when not passed a block" do
          attr_reader :relation
          before do
            @relation = users_set
          end

          it "raises an ArgumentError" do
            lambda do
              relation.on_remove
            end.should raise_error(ArgumentError)
          end
        end
      end
    end
  end
end
