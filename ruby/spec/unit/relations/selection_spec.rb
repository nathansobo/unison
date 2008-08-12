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
      end

      describe "#to_sql" do
        context "when #operand is a Set" do
          before do
            @selection = users_set.where(users_set[:id].eq(1))
          end

          it "returns 'select #operand where #predicate'" do
            selection.to_sql.should be_like("SELECT `users`.`id`, `users`.`name`, `users`.`hobby` FROM `users` WHERE `users`.`id` = 1")
          end
        end

        context "when #operand is a Selection" do
          before do
            @selection = users_set.where(users_set[:id].eq(1)).where(users_set[:name].eq("Nathan"))
          end

          it "returns 'select #operand where #predicate'" do
            selection.to_sql.should be_like("
              SELECT `users`.`id`, `users`.`name`, `users`.`hobby`
              FROM `users`
              WHERE `users`.`id` = 1 AND `users`.`name` = 'Nathan'
            ")
          end
        end
      end

      describe "#to_arel" do
        it "returns an Arel representation of the relation" do
          selection.to_arel.should == operand.to_arel.where(predicate.to_arel)
        end
      end

      context "after #retain has been called" do
        before do
          selection.retain(Object.new)
          selection.tuples
        end

        describe "#merge" do
          it "calls #merge on the #operand" do
            tuple = Photo.new(:id => 100, :user_id => 1, :name => "Photo 100")
            operand.find(tuple[:id]).should be_nil
            operand.should_not include(tuple)
            mock.proxy(operand).merge([tuple])

            selection.merge([tuple])

            operand.should include(tuple)
          end
        end

        describe "#size" do
          it "returns the number of tuples in the relation" do
            selection.size.should == selection.tuples.size
          end
        end

        describe "#after_last_release" do
          it "unsubscribes from and releases its #operand" do
            operand.extend AddSubscriptionsMethodToRelation
            selection.operand_subscriptions.should_not be_empty
            operand.should be_retained_by(selection)

            selection.operand_subscriptions.each do |subscription|
              operand.subscriptions.should include(subscription)
            end

            selection.send(:after_last_release)

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
              public :update_subscription_node
            end

            selection.predicate_subscription.should_not be_nil
            predicate.should be_retained_by(selection)
            predicate.update_subscription_node.should include(selection.predicate_subscription)

            selection.send(:after_last_release)

            predicate.should_not be_retained_by(selection)
            predicate.update_subscription_node.should_not include(selection.predicate_subscription)
          end
        end

        context "when the #predicate is updated" do
          attr_reader :user, :new_photos, :old_photos
          before do
            @user = User.find(1)
            @predicate = photos_set[:user_id].eq(user.signal(:id))
            @selection = Selection.new(photos_set, predicate).retain(Object.new)
            @old_photos = selection.tuples.dup
            old_photos.length.should == 2
            @new_photos = [ Photo.create(:id => 100, :user_id => 100, :name => "Photo 100"),
                            Photo.create(:id => 101, :user_id => 100, :name => "Photo 101") ]
          end

          context "for Tuples that match the new Predicate but not the old one" do
            it "inserts the Tuples in the set" do
              new_photos.each{|tuple| selection.tuples.should_not include(tuple)}
              user[:id] = 100
              new_photos.each{|tuple| selection.tuples.should include(tuple)}
            end

            it "invokes #on_insert callbacks for the inserted Tuples" do
              inserted_tuples = []
              selection.on_insert do |tuple|
                inserted_tuples << tuple
              end
              user[:id] = 100
              inserted_tuples.should == new_photos
            end

            it "#retains inserted Tuples" do
              new_photos.each{|tuple| tuple.should_not be_retained_by(selection)}
              user[:id] = 100
              new_photos.each{|tuple| tuple.should be_retained_by(selection)}
            end
          end

          context "for Tuples that matched the old Predicate but not the new one" do
            it "deletes the Tuples from the set" do
              old_photos.each{|tuple| selection.tuples.should include(tuple)}
              user[:id] = 100
              old_photos.each{|tuple| selection.tuples.should_not include(tuple)}
            end

            it "invokes #on_delete callbacks for the deleted Tuples" do
              deleted_tuples = []
              selection.on_delete do |tuple|
                deleted_tuples << tuple
              end
              user[:id] = 100
              deleted_tuples.should == old_photos
            end

            it "#releases deleted Tuples"  do
              old_photos.each{|tuple| tuple.should be_retained_by(selection)}
              user[:id] = 100
              old_photos.each{|tuple| tuple.should_not be_retained_by(selection)}
            end
          end

          context "for Tuples that match both the old and new Predicates" do
            # TODO: JN/NS - No predicate types currently exist that could allow a tuple to match two different predicates.
            it "keeps the Tuples in the set"
            it "does not invoke #on_insert callbacks for the Tuples"
            it "does not invoke #on_delete callbacks for the Tuples"
            it "continues to #retain the Tuples"
          end
        end

        context "when a Tuple is inserted into the #operand" do
          context "when the Tuple matches the #predicate" do
            before do
              @photo = Photo.new(:id => 100, :user_id => 1, :name => "Photo 100")
              predicate.eval(photo).should be_true
            end

            it "is added to the objects returned by #tuples" do
              selection.tuples.should_not include(photo)
              photos_set.insert(photo)
              selection.tuples.should include(photo)
            end

            it "invokes #on_insert callbacks" do
              on_insert_tuple = nil
              selection.on_insert do |tuple|
                on_insert_tuple = tuple
              end

              photos_set.insert(photo)
              on_insert_tuple.should == photo
            end

            it "is #retained by the Selection" do
              photo.should_not be_retained_by(selection)
              photos_set.insert(photo)
              photo.should be_retained_by(selection)              
            end
          end

          context "when the Tuple does not match the #predicate" do
            before do
              @photo = Photo.new(:id => 100, :user_id => 2, :name => "Photo 100")
              predicate.eval(photo).should be_false
            end

            it "is not added to the objects returned by #tuples" do
              selection.tuples.should_not include(photo)
              photos_set.insert(photo)
              selection.tuples.should_not include(photo)
            end

            it "does not invoke #on_insert callbacks" do
              selection.on_insert do |tuple|
                raise "Don't call me"
              end
              photos_set.insert(photo)
            end

            it "is not #retained by the Selection" do
              photo.should_not be_retained_by(selection)
              photos_set.insert(photo)
              photo.should_not be_retained_by(selection)
            end
          end
        end

        context "when a Tuple in the #operand that does not match the #predicate is updated" do
          before do
            @photo = Photo.create(:id => 100, :user_id => 2, :name => "Photo 100")
          end

          context "when the update causes the Tuple to match the #predicate" do
            it "adds the Tuple to the result of #tuples" do
              selection.tuples.should_not include(photo)
              photo[:user_id] = 1
              selection.tuples.should include(photo)
            end

            it "invokes #on_insert callbacks" do
              on_insert_tuple = nil
              selection.on_insert do |tuple|
                on_insert_tuple = tuple
              end
              selection.tuples.should_not include(photo)

              photo[:user_id] = 1
              on_insert_tuple.should == photo
            end

            it "is #retained by the Selection" do
              photo.should_not be_retained_by(selection)
              photo[:user_id] = 1
              photo.should be_retained_by(selection)              
            end
          end

          context "when the update does not cause the Tuple to match the #predicate" do
            it "does not add the Tuple into the result of #tuples" do
              selection.tuples.should_not include(photo)
              photo[:user_id] = 3
              selection.tuples.should_not include(photo)
            end

            it "does not invoke the #on_insert event" do
              selection.on_insert do |tuple|
                raise "Dont call me"
              end

              photo[:user_id] = 3
            end

            it "is not #retained by the Selection" do
              photo.should_not be_retained_by(selection)
              photo[:user_id] = 3
              photo.should_not be_retained_by(selection)              
            end
          end
        end

        context "when a Tuple that matches the #predicate in the #operand is updated" do
          before do
            @photo = selection.tuples.first
          end

          context "when the update causes the Tuple to not match the #predicate" do
            it "removes the Tuple from the result of #tuples" do
              selection.tuples.should include(photo)
              photo[:user_id] = 3
              selection.tuples.should_not include(photo)
            end

            it "invokes the on_delete event" do
              on_delete_tuple = nil
              selection.on_delete do |tuple|
                on_delete_tuple = tuple
              end

              photo[:user_id] = 3
              on_delete_tuple.should == photo
            end

            it "#releases the deleted Tuple" do
              photo.should be_retained_by(selection)
              photo[:user_id] = 3
              photo.should_not be_retained_by(selection)
            end
          end

          context "when the Tuple continues to match the #predicate after the update" do
            it "does not change the size of the result of #tuples" do
              selection.tuples.should include(photo)
              lambda do
                photo[:name] = "New Name"
              end.should_not change {selection.tuples.size}
              selection.tuples.should include(photo)
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

            it "does not #release the deleted Tuple" do
              photo.should be_retained_by(selection)
              photo[:name] = "James Brown"
              photo.should be_retained_by(selection)
            end
          end
        end

        context "when a Tuple is deleted from the #operand" do
          context "when the Tuple matches the #predicate" do
            attr_reader :photo
            before do
              @photo = selection.tuples.first
              predicate.eval(photo).should be_true
            end

            it "is deleted from the objects returned by #tuples" do
              selection.tuples.should include(photo)
              photos_set.delete(photo)
              selection.tuples.should_not include(photo)
            end

            it "invokes #on_delete callbacks" do
              deleted = nil
              selection.on_delete do |tuple|
                deleted = tuple
              end

              photos_set.delete(photo)
              deleted.should == photo
            end

            it "#releases the deleted Tuple" do
              photo.should be_retained_by(selection)
              photos_set.delete(photo)
              photo.should_not be_retained_by(selection)
            end
          end

          context "when the Tuple does not match the #predicate" do
            attr_reader :photo
            before do
              @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")
              predicate.eval(photo).should be_false
            end

            it "is not deleted from the objects returned by #tuples" do
              selection.tuples.should_not include(photo)
              photos_set.delete(photo)
              selection.tuples.should_not include(photo)
            end

            it "does not invoke #on_delete callbacks" do
              selection.on_delete do |tuple|
                raise "Don't call me"
              end
              photos_set.delete(photo)
            end
          end
        end
      end

      context "before #retain has been called" do
        describe "#retain" do
          it "retains and subscribes to its #predicate" do
            selection.predicate_subscription.should be_nil
            predicate.should_not be_retained_by(selection)

            selection.retain(Object.new)
            selection.predicate_subscription.should_not be_nil
            predicate.should be_retained_by(selection)
          end

          it "retains and subscribes to its #operand" do
            selection.operand_subscriptions.should be_empty
            operand.should_not be_retained_by(selection)

            selection.retain(Object.new)
            selection.operand_subscriptions.should_not be_empty
            operand.should be_retained_by(selection)
          end

          it "retains the Tuples inserted by initial_read" do
            selection.retain(Object.new)
            selection.should_not be_empty
            selection.each do |tuple|
              tuple.should be_retained_by(selection)
            end
          end
        end

        describe "#tuples" do
          it "returns all tuples in its #operand for which its #predicate returns true" do
            tuples = selection.tuples
            tuples.size.should == 2
            tuples.each do |tuple|
              tuple[:user_id].should == 1
            end
          end
        end

        describe "#merge" do
          it "raises an Exception" do
            lambda do
              selection.merge([Photo.new(:id => 100, :user_id => 1, :name => "Photo 100")])
            end.should raise_error
          end
        end
      end
    end
  end
end