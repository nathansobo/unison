require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

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

        context "when a Tuple inserted into #operand_1 creates a compound Tuple that matches the #predicate" do
          attr_reader :photo, :user, :tuple_class, :expected_tuple
          before do
            @tuple_class = join.tuple_class
            @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")
            @user = User.new(:id => 100, :name => "Brian")
            @expected_tuple = tuple_class.new(user, photo)
            join.predicate.eval(expected_tuple).should be_true
          end

          it "adds the compound Tuple to the result of #read" do
            join.read.should_not include(expected_tuple)
            users_set.insert(user)
            join.read.should include(expected_tuple)
          end
        end

        context "when a Tuple inserted into #operand_1 creates a compound Tuple that does not match the #predicate" do
          attr_reader :photo, :user, :tuple_class, :expected_tuple
          before do
            @tuple_class = join.tuple_class
            @photo = Photo.create(:id => 100, :user_id => 999, :name => "Photo 100")
            @user = User.new(:id => 100, :name => "Brian")
            @expected_tuple = tuple_class.new(user, photo)
            join.predicate.eval(expected_tuple).should be_false
          end

          it "does not add the compound Tuple to the result of #read" do
            join.read.should_not include(expected_tuple)
            users_set.insert(user)
            join.read.should_not include(expected_tuple)
          end
        end

        context "when a Tuple inserted into #operand_2 creates a compound Tuple that matches the #predicate" do
          attr_reader :photo, :user, :tuple_class, :expected_tuple
          before do
            @tuple_class = join.tuple_class
            @photo = Photo.new(:id => 100, :user_id => 100, :name => "Photo 100")
            @user = User.create(:id => 100, :name => "Brian")
            @expected_tuple = tuple_class.new(user, photo)
            join.predicate.eval(expected_tuple).should be_true
          end

          it "adds the compound Tuple to the result of #read" do
            join.read.should_not include(expected_tuple)
            photos_set.insert(photo)
            join.read.should include(expected_tuple)
          end
        end

        context "when a Tuple inserted into #operand_2 creates a compound Tuple that does not match the #predicate" do
          attr_reader :photo, :user, :tuple_class, :expected_tuple
          before do
            @tuple_class = join.tuple_class
            @photo = Photo.new(:id => 100, :user_id => 999, :name => "Photo 100")
            @user = User.create(:id => 100, :name => "Brian")
            @expected_tuple = tuple_class.new(user, photo)
            join.predicate.eval(expected_tuple).should be_false
          end

          it "does not add the compound Tuple to the result of #read" do
            join.read.should_not include(expected_tuple)
            photos_set.insert(photo)
            join.read.should_not include(expected_tuple)
          end
        end

      end

      describe "#read" do
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

      describe "#on_insert" do
        context "when passed a block" do
          context "when a Tuple is inserted into #operand_2" do
            it "will invoke the block when the insertion results in a compound Tuple that matches the #predicate" do
              inserted = nil
              join.on_insert do |tuple|
                inserted = tuple
              end
              photo = Photo.create(:id => 100, :user_id => 1, :name => "Photo 100")

              inserted[photos_set].should == photo
              inserted[users_set].should == User.find(1)
            end
          end
        end

        context "when not passed a block" do
          it "raises an ArgumentError" do
            lambda do
              join.on_insert
            end.should raise_error(ArgumentError)
          end
        end
      end      
    end
  end
end
