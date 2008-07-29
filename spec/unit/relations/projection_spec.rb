require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

module Unison
  module Relations
    describe Projection do
      attr_reader :operand, :projection, :attributes
      before do
        @operand = InnerJoin.new(users_set, photos_set, photos_set[:user_id].eq(users_set[:id]))
        @attributes = users_set
        @projection = Projection.new(operand, attributes)
      end

      describe "#initialize" do
        it "sets #operand and #attributes" do
          projection.operand.should == operand
          projection.attributes.should == attributes
        end

        context "when the a Tuple is inserted into the #operand" do
          attr_reader :user
          before do
            @user = User.create(:id => 100, :name => "Brian")
          end

          it "inserts the Tuple restricted by #attributes into itself" do
            projection.read.should_not include(user)
            lambda do
              Photo.create(:id => 100, :user_id => user[:id], :name => "Photo 100")
            end.should change{projection.read.length}.by(1)
            projection.read.should include(user)
          end
        end
      end

      describe "#read" do
        it "returns a set restricted to #attributes from the #operand" do
          projection.read.should == operand.read.map {|tuple| tuple[attributes]}.uniq
        end
      end

      describe "#on_insert" do
        context "when passed a block" do
          attr_reader :user
          before do
            @user = User.create(:id => 100, :name => "Brian")
          end
          
          it "will invoke the block when tuples are inserted" do
            inserted = nil
            projection.on_insert do |tuple|
              inserted = tuple
            end
            Photo.create(:id => 100, :user_id => user[:id], :name => "Photo 100")

            inserted.should == user
          end
        end

        context "when not passed a block" do
          it "raises an ArgumentError" do
            lambda do
              projection.on_insert
            end.should raise_error(ArgumentError)
          end
        end
      end
    end
  end
end
