require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

module Unison
  module Relations
    describe Selection do
      attr_reader :operand, :selection, :predicate, :photo
      before do
        @operand = photos_set
        @predicate = operand[:user_id].eq(1)
        @selection = Selection.new(operand, predicate)
      end

      describe "#initialize" do
        it "sets the #operand and #predicate" do
          selection.operand.should == photos_set
          predicate.should == photos_set[:user_id].eq(1)
        end

        it "retains its #predicate" do
          predicate.should be_retained_by(selection)
        end

        it "retains its #operand" do
          operand.should be_retained_by(selection)
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

        context "when a Tuple in the #operand that does not match the #predicate is updated" do
          before do
            @photo = Photo.create(:id => 100, :user_id => 2, :name => "Photo 100")
          end

          context "when the update causes the Tuple to match the #predicate" do
            it "adds the Tuple to the result of #read" do
              selection.read.should_not include(photo)
              photo[:user_id] = 1
              selection.read.should include(photo)
            end

            it "invokes the #on_insert event" do
              on_insert_tuple = nil
              selection.on_insert do |tuple|
                on_insert_tuple = tuple
              end

              photo[:user_id] = 1
              on_insert_tuple.should == photo
            end
          end

          context "when the update does not cause the Tuple to match the #predicate" do
            it "does not add the Tuple into the result of #read" do
              selection.read.should_not include(photo)
              photo[:user_id] = 3
              selection.read.should_not include(photo)
            end

            it "does not invoke the #on_insert event" do
              selection.on_insert do |tuple|
                raise "Dont call me"
              end

              photo[:user_id] = 3
            end
          end
        end

        context "when a Tuple that matches the #predicate in the #operand is updated" do
          before do
            @photo = selection.read.first
          end

          context "when the update causes the Tuple to not match the #predicate" do
            it "removes the Tuple from the result of #read" do
              selection.read.should include(photo)
              photo[:user_id] = 3
              selection.read.should_not include(photo)
            end

            it "invokes the on_delete event" do
              on_delete_tuple = nil
              selection.on_delete do |tuple|
                on_delete_tuple = tuple
              end

              photo[:user_id] = 3
              on_delete_tuple.should == photo
            end
          end

          context "when the Tuple continues to match the #predicate after the update" do
            it "does not change the size of the result of #read" do
              selection.read.should include(photo)
              lambda do
                photo[:name] = "New Name"
              end.should_not change {selection.read.size}
              selection.read.should include(photo)
            end

            it "invokes the #on_tuple_update event" do
              arguments = []
              selection.on_tuple_update do |tuple, attribute, old_value, new_value|
                arguments.push [tuple, attribute, old_value, new_value]
              end

              old_value = photo[:name]
              new_value = "New Name"
              photo[:name] = new_value
              arguments.should == [[photo, photos_set[:name], old_value, new_value]]
            end

            it "does not invoke the #on_insert or #on_delete event" do
              selection.on_insert do |tuple|
                raise "Dont call me"
              end
              selection.on_delete do |tuple|
                raise "Dont call me"
              end

              photo[:name] = "New Name"
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

      describe "#destroy" do
        it "unsubscribes from and releases its #operand" do
          operand.extend AddSubscriptionsMethodToRelation
          selection.operand_subscriptions.should_not be_empty
          operand.should be_retained_by(selection)

          selection.operand_subscriptions.each do |subscription|
            operand.subscriptions.should include(subscription)
          end

          selection.send(:destroy)

          operand.should_not be_retained_by(selection)
          selection.operand_subscriptions.each do |subscription|
            operand.subscriptions.should_not include(subscription)
          end
        end

        it "unsubscribes from and releases its #predicate" do
          class << selection
            public :predicate_subscription
          end
          class << predicate
            public :update_subscriptions
          end

          selection.predicate_subscription.should_not be_nil
          predicate.should be_retained_by(selection)
          predicate.update_subscriptions.should include(selection.predicate_subscription)

          selection.send(:destroy)

          predicate.should_not be_retained_by(selection)
          predicate.update_subscriptions.should_not include(selection.predicate_subscription)
        end
      end
    end
  end
end