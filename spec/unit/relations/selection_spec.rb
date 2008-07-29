require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

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

        context "when a Tuple that matches the #predicate is inserted into the #operand" do
          attr_reader :photo
          before do
            @photo = Photo.new(:id => 100, :user_id => 1, :name => "Photo 100")
            selection.predicate.eval(photo).should be_true
          end

          it "is added to the objects returned by #read" do
            selection.read.should_not include(photo)
            photos_set.insert(photo)
            selection.read.should include(photo)
          end
        end

        context "when a Tuple that does not match the #predicate is inserted into the #operand" do
          attr_reader :photo
          before do
            @photo = Photo.new(:id => 100, :user_id => 2, :name => "Photo 100")
            selection.predicate.eval(photo).should be_false
          end

          it "is not added to the objects returned by #read" do
            selection.read.should_not include(photo)
            photos_set.insert(photo)
            selection.read.should_not include(photo)
          end
        end
      end

      describe "#read" do
        it "returns all tuples in its #operand for which its #predicate returns true" do
          tuples = selection.read
          tuples.size.should == 2
          tuples.each do |tuple|
            tuple[:user_id].should == 1
          end
        end
      end

      describe "#on_insert" do
        it "will invoke the block when tuples are inserted" do
          inserted = nil
          selection.on_insert do |tuple|
            inserted = tuple
          end
          photo = Photo.new(:id => 100, :user_id => 1, :name => "Photo 100")
          selection.predicate.eval(photo).should be_true
          photos_set.insert(photo)

          inserted.should == photo
        end
      end

      describe "#size" do
        it "returns the number of tuples in the relation" do
          selection.size.should == selection.read.size
        end
      end

      describe "#==" do
        it "returns true for Selections with the same #operand and #predicate and false otherwise" do
          selection.should == Selection.new(photos_set, photos_set[:user_id].eq(1))
          selection.should_not == Selection.new(users_set, photos_set[:user_id].eq(1))
          selection.should_not == Selection.new(photos_set, photos_set[:user_id].eq(2))
          selection.should_not == Object.new
        end
      end
    end
  end
end