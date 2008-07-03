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

        it "sets the #tuple_class to an anonymous subclass of CompoundTuple::Base" do
          join.tuple_class.superclass.should == CompoundTuple::Base
        end
      end

      describe "#read" do
        before do
          users_set.insert(user_class.new(:id => 1, :name => "Nathan"))
          users_set.insert(user_class.new(:id => 2, :name => "Corey"))
          users_set.insert(user_class.new(:id => 3, :name => "Ross"))
          photos_set.insert(photo_class.new(:id => 1, :user_id => 1, :name => "Photo 1"))
          photos_set.insert(photo_class.new(:id => 2, :user_id => 1, :name => "Photo 2"))
          photos_set.insert(photo_class.new(:id => 3, :user_id => 2, :name => "Photo 3"))
        end

        it "returns all tuples in its operands for which its predicate returns true" do
          tuples = join.read
          tuples.size.should == 3

          tuples[0][users_set[:id]].should == 1
          tuples[0][users_set[:name]].should == "Nathan"
          tuples[0][photos_set[:id]].should == 1
          tuples[0][photos_set[:user_id]].should == 1
          tuples[0][photos_set[:name]].should == "Photo 1"

          tuples[1][users_set[:id]].should == 1
          tuples[1][users_set[:name]].should == "Nathan"
          tuples[1][photos_set[:id]].should == 2
          tuples[1][photos_set[:user_id]].should == 1
          tuples[1][photos_set[:name]].should == "Photo 2"

          tuples[2][users_set[:id]].should == 2
          tuples[2][users_set[:name]].should == "Corey"
          tuples[2][photos_set[:id]].should == 3
          tuples[2][photos_set[:user_id]].should == 2
          tuples[2][photos_set[:name]].should == "Photo 3"
        end
      end
    end
  end
end
