require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

module Unison
  module Relations
    describe Selection do
      attr_reader :selection, :predicate
      before do
        @predicate = photos_set[:user_id].eq(1)
        @selection = Selection.new(photos_set, predicate)
      end

      describe "#initialize" do
        it "sets the #operand and #predicate" do
          selection.operand.should == photos_set
          predicate.should == photos_set[:user_id].eq(1)
        end

        context "when the #predicate is updated" do
          attr_reader :user, :new_photo, :old_photos
          before do
            @user = User.find(1)
            @predicate = photos_set[:user_id].eq(user.signal(:id))
            @selection = Selection.new(photos_set, predicate)
            @old_photos = selection.read.dup
            @new_photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")
          end

          it "reloads the contents of #read" do
            selection.read.should_not == [new_photo]
            user[:id] = 100
            selection.read.should == [new_photo]
          end

          it "invokes #on_insert callbacks for Tuples inserted into the Relation" do
            inserted_photos = []
            selection.on_insert do |photo|
              inserted_photos.push photo
            end
            user[:id] = 100
            inserted_photos.should == [new_photo]
          end

          it "invokes #on_delete callbacks for Tuples deleted from the Relation" do
            deleted_photos = []
            selection.on_delete do |photo|
              deleted_photos.push photo
            end
            user[:id] = 100
            deleted_photos.should == old_photos
          end
        end

        context "when a Tuple is inserted into the #operand" do
          context "when the Tuple matches the #predicate" do
            attr_reader :photo
            before do
              @photo = Photo.new(:id => 100, :user_id => 1, :name => "Photo 100")
              predicate.eval(photo).should be_true
            end

            it "is added to the objects returned by #read" do
              selection.read.should_not include(photo)
              photos_set.insert(photo)
              selection.read.should include(photo)
            end
          end

          context "when the Tuple does not match the #predicate" do
            attr_reader :photo
            before do
              @photo = Photo.new(:id => 100, :user_id => 2, :name => "Photo 100")
              predicate.eval(photo).should be_false
            end

            it "is not added to the objects returned by #read" do
              selection.read.should_not include(photo)
              photos_set.insert(photo)
              selection.read.should_not include(photo)
            end
          end
        end

        context "when a Tuple is deleted into the #operand" do
          context "when the Tuple matches the #predicate" do
            attr_reader :photo
            before do
              @photo = selection.read.first
              predicate.eval(photo).should be_true
            end

            it "is deleted from the objects returned by #read" do
              selection.read.should include(photo)
              photos_set.delete(photo)
              selection.read.should_not include(photo)
            end
          end

          context "when the Tuple does not match the #predicate" do
            attr_reader :photo
            before do
              @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")
              predicate.eval(photo).should be_false
            end

            it "is not deleted from the objects returned by #read" do
              selection.read.should_not include(photo)
              photos_set.delete(photo)
              selection.read.should_not include(photo)
            end
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
        attr_reader :photo
        context "when a Tuple that matches the #predicate is inserted into the #operand" do
          before do
            @photo = Photo.new(:id => 100, :user_id => 1, :name => "Photo 100")
            predicate.eval(photo).should be_true
          end

          it "invokes the block with the Tuple" do
            inserted = nil
            selection.on_insert do |tuple|
              inserted = tuple
            end
            photos_set.insert(photo)

            inserted.should == photo
          end
        end

        context "when a Tuple that does not match the #predicate is inserted into the #operand" do
          before do
            @photo = Photo.new(:id => 100, :user_id => 100, :name => "Photo 100")
            predicate.eval(photo).should be_false
          end

          it "does not invoke the block" do
            selection.on_insert do |tuple|
              raise "I should not be invoked"
            end
            photos_set.insert(photo)
          end
        end
      end

      describe "#on_delete" do
        attr_reader :photo
        context "when a Tuple that matches the #predicate is deleted from the #operand" do
          before do
            @photo = Photo.create(:id => 100, :user_id => 1, :name => "Photo 100")
            predicate.eval(photo).should be_true
            selection.read.should include(photo)
          end

          it "invokes the block with the Tuple" do
            deleted = nil
            selection.on_delete do |tuple|
              deleted = tuple
            end

            photos_set.delete(photo)
            deleted.should == photo
          end
        end

        context "when a Tuple that does not match the #predicate is deleted from the #operand" do
          before do
            @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")
            predicate.eval(photo).should be_false
            selection.read.should_not include(photo)
          end

          it "does not invoke the block" do
            selection.on_delete do |tuple|
              raise "I should not be invoked"
            end
            photos_set.delete(photo)
          end
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
          selection.should_not == Selection.new(photos_set, photos_set[:user_id].eq(2))
          selection.should_not == Object.new
        end
      end
    end
  end
end