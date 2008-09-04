require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Relations
    describe InnerJoin do
      attr_reader :join, :predicate, :operand_1, :operand_2
      before do
        @operand_1 = users_set
        @operand_2 = photos_set
        @predicate = photos_set[:user_id].eq(users_set[:id])
        @join = InnerJoin.new(operand_1, operand_2, predicate)
      end

      describe "#initialize" do
        it "sets #operand_1, #operand_2, and #predicate" do
          join.operand_1.should == users_set
          join.operand_2.should == photos_set
          predicate.should == photos_set[:user_id].eq(users_set[:id])
        end

        context "when passed in #predicate is a constant value Predicate" do
          it "raises an ArgumentError"
        end
      end

      describe "#to_sql" do
        it "returns 'select #operand_1 inner join #operand_2 on #predicate'" do
          join.to_sql.should be_like("
            SELECT `users`.`id`, `users`.`name`, `users`.`hobby`, `users`.`team_id`, `photos`.`id`, `photos`.`user_id`, `photos`.`camera_id`, `photos`.`name`
            FROM `users`
            INNER JOIN `photos`
            ON `photos`.`user_id` = `users`.`id`
          ")
        end
      end

      describe "#to_arel" do
        it "returns an Arel representation of the relation" do
          join.to_arel.should == operand_1.to_arel.join(operand_2.to_arel).on(predicate.to_arel)
        end
      end

      describe "#push" do
        before do
          origin.connection[:users].delete
          origin.connection[:photos].delete
        end

        context "when #composed_sets.size == 2" do
          it "pushes a Projection of both composed_sets represented in the InnerJoin to the given Repository" do
            users_projection = join.project(users_set)
            photos_projection = join.project(photos_set)

            mock.proxy(origin).push(users_projection)
            mock.proxy(origin).push(photos_projection)

            join.push(origin)

            users_projection.pull(origin).should == users_projection.tuples
            photos_projection.pull(origin).should == photos_projection.tuples
          end
        end

        context "when #composed_sets.size == 3" do
          before do
            @join = join.join(cameras_set).on(photos_set[:camera_id].eq(cameras_set[:id]))
            join.composed_sets.size.should == 3
          end

          it "pushes a Projection of the three composed_sets represented in the InnerJoin to the given Repository" do
            users_projection = join.project(users_set)
            photos_projection = join.project(photos_set)
            cameras_projection = join.project(cameras_set)

            mock.proxy(origin).push(users_projection)
            mock.proxy(origin).push(photos_projection)
            mock.proxy(origin).push(cameras_projection)

            join.push(origin)

            users_projection.pull(origin).should == users_projection.tuples
            photos_projection.pull(origin).should == photos_projection.tuples
            cameras_projection.pull(origin).should == cameras_projection.tuples
          end
        end
      end

      describe "#compound?" do
        it "returns true" do
          join.should be_compound
        end
      end

      describe "#set" do
        it "raises a NotImplementedError" do
          lambda do
            join.set
          end.should raise_error(NotImplementedError)
        end
      end

      describe "#composed_sets" do
        context "when the operands contain PrimitiveTuples" do
          it "returns the union of the #composed_sets of the operands" do
            join.composed_sets.should == operand_1.composed_sets + operand_2.composed_sets
          end
        end

        context "when one of operands contains CompositeTuples" do
          before do
            @join = join.join(cameras_set).on(photos_set[:camera_id].eq(cameras_set[:id]))
          end

          it "returns the union of the #composed_sets of the operands" do
            join.composed_sets.should == [users_set, photos_set, cameras_set]
          end
        end
      end

      describe "#attribute" do
        attr_reader :name

        context "when an Attribute with the given name is defined on both operands" do
          before do
            @name = :name
            operand_1.should have_attribute(name)
            operand_2.should have_attribute(name)
          end

          it "returns the value of #operand_1.attribute for the name" do
            join.attribute(name).should == operand_1.attribute(name)
          end
        end

        context "when an Attribute with the given #name is defined only on #operand_2" do
          before do
            @name = :user_id
            operand_1.should_not have_attribute(name)
            operand_2.should have_attribute(name)
          end

          it "returns the value of #operand_1.attribute for the name" do
            join.attribute(name).should == operand_2.attribute(name)
          end
        end

        context "when no operand has an Attribute with the given name" do
          before do
            @name = :hussein
            operand_1.should_not have_attribute(name)
            operand_2.should_not have_attribute(name)
          end

          it "raises an ArgumentError" do
            lambda do
              join.attribute(name)
            end.should raise_error(ArgumentError)
          end
        end
      end

      describe "#merge" do
        it "raises a NotImplementedError" do
          lambda do
            join.merge([])
          end.should raise_error(NotImplementedError)
        end
      end

      describe "attribute" do
        context "when #operand_1.has_attribute? is true" do
          it "delegates to #operand_1" do
            operand_1_attribute = operand_1.attribute(:id)
            operand_1_attribute.should_not be_nil

            mock.proxy(operand_1).attribute(:id)
            join.attribute(:id).should == operand_1_attribute
          end
        end

        context "when #operand_1.has_attribute? is false" do
          it "delegates to #operand_2" do
            operand_1.should_not have_attribute(:user_id)
            operand_2.should have_attribute(:user_id)
            operand_2_attribute = operand_2.attribute(:user_id)

            dont_allow(operand_1).attribute(:user_id)
            mock.proxy(operand_2).attribute(:user_id)
            join.attribute(:user_id).should == operand_2_attribute
          end
        end
      end

      describe "#has_attribute?" do
        context "when #operand_1.has_attribute? is true" do
          it "delegates to #operand_1" do
            operand_1.has_attribute?(:id).should be_true

            mock.proxy(operand_1).has_attribute?(:id)
            join.has_attribute?(:id).should be_true
          end
        end

        context "when #operand_1.has_attribute? is false" do
          it "delegates to #operand_1 and #operand_2" do
            operand_1.has_attribute?(:user_id).should be_false
            operand_2.has_attribute?(:user_id).should be_true

            mock.proxy(operand_1).has_attribute?(:user_id)
            mock.proxy(operand_2).has_attribute?(:user_id)
            join.has_attribute?(:user_id).should be_true
          end
        end
      end

      context "when #retained?" do
        attr_reader :retainer
        before do
          @retainer = Object.new
          join.retained_by(retainer)
        end

        context "when a Tuple inserted into #operand_1" do
          context "when the inserted Tuple creates a compound Tuple that matches the #predicate" do
            attr_reader :photo, :user, :tuple_class, :expected_tuple
            before do
              @tuple_class = CompositeTuple::Base
              @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")
              @user = User.new(:id => 100, :name => "Brian")
              @expected_tuple = tuple_class.new(user, photo)
              predicate.eval(expected_tuple).should be_true
            end

            it "adds the CompositeTuple to the result of #tuples" do
              join.should_not include(expected_tuple)
              users_set.insert(user)
              join.should include(expected_tuple)
            end

            it "triggers the on_insert event" do
              inserted = nil
              join.on_insert do |tuple|
                inserted = tuple
              end
              users_set.insert(user)

              predicate.eval(inserted).should be_true
              inserted[photos_set].should == photo
              inserted[users_set].should == user
            end

            it "retains the CompositeTuple" do
              join.find(user.id).should be_nil
              users_set.insert(user)
              join.find(user.id).should be_retained_by(join)
            end
          end

          context "when the inserted Tuple creates a compound Tuple that does not match the #predicate" do
            attr_reader :photo, :user, :tuple_class, :expected_tuple
            before do
              @tuple_class = CompositeTuple::Base
              @photo = Photo.create(:id => 100, :user_id => 999, :name => "Photo 100")
              @user = User.new(:id => 100, :name => "Brian")
              @expected_tuple = tuple_class.new(user, photo)
              predicate.eval(expected_tuple).should be_false
            end

            it "does not add the compound Tuple to the result of #tuples" do
              join.should_not include(expected_tuple)
              users_set.insert(user)
              join.should_not include(expected_tuple)
            end

            it "does not trigger the on_insert event" do
              join.on_insert do |tuple|
                raise "I should not be invoked"
              end
              users_set.insert(user)
            end

            it "does not retain the CompositeTuple" do
              join.find(user.id).should be_nil
              users_set.insert(user)
              join.find(user.id).should be_nil
            end
          end
        end

        context "when a Tuple inserted into #operand_2" do
          context "when the inserted Tuple creates a compound Tuple that matches the #predicate" do
            attr_reader :photo, :user, :tuple_class, :expected_tuple
            before do
              @tuple_class = CompositeTuple::Base
              @photo = Photo.new(:id => 100, :user_id => 100, :name => "Photo 100")
              @user = User.create(:id => 100, :name => "Brian")
              @expected_tuple = tuple_class.new(user, photo)
              predicate.eval(expected_tuple).should be_true
            end

            it "adds the compound Tuple to the result of #tuples" do
              join.should_not include(expected_tuple)
              photos_set.insert(photo)
              join.should include(expected_tuple)
            end

            it "trigger the on_insert event" do
              inserted = nil
              join.on_insert do |tuple|
                inserted = tuple
              end
              photos_set.insert(photo)

              predicate.eval(inserted).should be_true
              inserted[photos_set].should == photo
              inserted[users_set].should == user
            end
            
            it "retains the CompositeTuple" do
              join.where(photos_set[:id].eq(photo[:id])).should be_empty
              photos_set.insert(photo)
              join.where(photos_set[:id].eq(photo[:id])).first.should be_retained_by(join)
            end
          end

          context "when the inserted Tuple creates a compound Tuple that does not match the #predicate" do
            attr_reader :photo, :user, :tuple_class, :expected_tuple
            before do
              @tuple_class = CompositeTuple::Base
              @photo = Photo.new(:id => 100, :user_id => 999, :name => "Photo 100")
              @user = User.create(:id => 100, :name => "Brian")
              @expected_tuple = tuple_class.new(user, photo)
              predicate.eval(expected_tuple).should be_false
            end

            it "does not add the compound Tuple to the result of #tuples" do
              join.should_not include(expected_tuple)
              photos_set.insert(photo)
              join.should_not include(expected_tuple)
            end

            it "does not trigger the on_insert event" do
              join.on_insert do |tuple|
                raise "I should not be invoked"
              end
              photos_set.insert(photo)
            end

            it "does not retain the CompositeTuple" do
              join.find(user.id).should be_nil
              photos_set.insert(photo)
              join.find(user.id).should be_nil
            end
          end
        end

        context "when a Tuple in #operand_1 is updated" do
          context "when the Tuple is not a member of a compound Tuple that matches the #predicate" do
            attr_reader :user, :photo, :expected_compound_tuple
            before do
              @user = users_set.tuples.first
              @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")
              @expected_compound_tuple = CompositeTuple::Base.new(user, photo)
            end

            context "when the update causes a compound Tuple to match the #predicate" do
              it "adds that compound Tuple to the result of #tuples" do
                join.should_not include(expected_compound_tuple)
                user[:id] = photo[:user_id]
                join.should include(expected_compound_tuple)
              end

              it "triggers the on_insert event" do
                inserted = nil
                join.on_insert do |tuple|
                  inserted = tuple
                end
                user[:id] = photo[:user_id]

                predicate.eval(inserted).should be_true
                inserted[photos_set].should == photo
                inserted[users_set].should == user
              end

              it "retains the CompositeTuple" do
                join.where(photos_set[:id].eq(photo[:id])).should be_empty
                user[:id] = photo[:user_id]
                join.where(photos_set[:id].eq(photo[:id])).tuples.first.should be_retained_by(join)
              end
            end

            context "when the update does not cause the Tuple to match the #predicate" do
              it "does not add the Tuple into the result of #tuples" do
                join.should_not include(expected_compound_tuple)
                user[:id] = photo[:user_id] + 1
                join.should_not include(expected_compound_tuple)
              end

              it "does not trigger the on_insert event" do
                join.on_insert do |tuple|
                  raise "Do not call me"
                end
                user[:id] = photo[:user_id] + 1
              end
            end
          end

          context "when the Tuple is a member of a compound Tuple that matches the #predicate" do
            attr_reader :compound_tuples, :user
            before do
              @user = User.find(1)
              @compound_tuples = join.select do |compound_tuple|
                compound_tuple[users_set] == user
              end
              compound_tuples.size.should be > 1
              compound_tuples.each do |compound_tuple|
                join.should include(compound_tuple)
              end
            end

            context "and the update causes the compound Tuple to not match the #predicate" do
              it "removes the Tuple from the result of #tuples" do
                user[:id] = 100
                compound_tuples.each do |compound_tuple|
                  join.should_not include(compound_tuple)
                end
              end

              it "triggers the on_delete event" do
                deleted = []
                join.on_delete do |tuple|
                  deleted.push tuple
                end
                user[:id] = 100
                deleted.size.should == compound_tuples.size
                compound_tuples.each do |compound_tuple|
                  deleted.should include(compound_tuple)
                end
              end

              it "releases the CompositeTuple" do
                compound_tuple = join.find(user.id)
                compound_tuple.should be_retained_by(join)
                user[:id] = 100
                compound_tuple.should_not be_retained_by(join)
              end
            end

            context "and the compound Tuple continues to match the #predicate after the update" do
              it "does not remove that compound Tuple from the results of #tuples" do
                user[:name] = "Joe"
                compound_tuples.each do |compound_tuple|
                  join.should include(compound_tuple)
                end
              end

              it "triggers the on_tuple_update event for the compound Tuple" do
                updated = []
                join.on_tuple_update do |tuple, attribute, old_value, new_value|
                  updated.push [tuple, attribute, old_value, new_value]
                end
                old_name = user[:name]
                user[:name] = "Joe"
                updated.size.should == compound_tuples.size
                compound_tuples.each do |compound_tuple|
                  updated.should include([compound_tuple, users_set[:name], old_name, "Joe"])
                end
              end

              it "does not trigger the on_insert or on_delete event" do
                join.on_insert do |tuple|
                  raise "Dont call me"
                end
                join.on_delete do |tuple|
                  raise "Dont call me"
                end
                user[:name] = "Joe"
              end
            end
          end
        end

        context "when a Tuple in #operand_2 is updated" do
          context "when the Tuple is not a member of a compound Tuple that matches the #predicate" do
            attr_reader :user, :photo, :expected_compound_tuple
            before do
              @user = users_set.tuples.first
              @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")
              @expected_compound_tuple = CompositeTuple::Base.new(user, photo)
            end

            context "when the update causes a compound Tuple to match the #predicate" do
              it "adds that compound Tuple to the result of #tuples" do
                join.should_not include(expected_compound_tuple)
                photo[:user_id] = user[:id]
                join.should include(expected_compound_tuple)
              end

              it "triggers the on_insert event" do
                inserted = nil
                join.on_insert do |tuple|
                  inserted = tuple
                end
                photo[:user_id] = user[:id]

                predicate.eval(inserted).should be_true
                inserted[photos_set].should == photo
                inserted[users_set].should == user
              end

              it "retains the CompositeTuple" do
                join.where(photos_set[:id].eq(photo[:id])).should be_empty
                photo[:user_id] = user[:id]
                join.where(photos_set[:id].eq(photo[:id])).first.should be_retained_by(join)
              end
            end

            context "when the update does not cause the Tuple to match the #predicate" do
              it "does not add the Tuple into the result of #tuples" do
                join.should_not include(expected_compound_tuple)
                photo[:user_id] = 1000
                join.should_not include(expected_compound_tuple)
              end

              it "does not trigger the on_insert event" do
                join.on_insert do |tuple|
                  raise "Do not call me"
                end
                photo[:user_id] = 1000
              end
            end
          end

          context "when the Tuple is a member of a compound Tuple that matches the #predicate" do
            attr_reader :compound_tuple, :photo
            before do
              @photo = photos_set.tuples.first
              @compound_tuple = join.tuples.find do |compound_tuple|
                compound_tuple[photos_set] == photo
              end
              join.should include(compound_tuple)
            end

            context "and the update causes the compound Tuple to not match the #predicate" do
              it "removes the Tuple from the result of #tuples" do
                photo[:user_id] = 100
                join.should_not include(compound_tuple)
              end

              it "triggers the on_delete event" do
                deleted = []
                join.on_delete do |tuple|
                  deleted.push tuple
                end
                photo[:user_id] = 100
                deleted.should == [compound_tuple]
              end

              it "releases the CompositeTuple" do
                compound_tuple = join.where(photos_set[:id].eq(photo.id)).first
                compound_tuple.should be_retained_by(join)

                photo[:user_id] = 100

                compound_tuple.should_not be_retained_by(join)
              end
            end

            context "and the compound Tuple continues to match the #predicate after the update" do
              it "does not remove that compound Tuple from the results of #tuples" do
                photo[:name] = "A great naked show"
                join.should include(compound_tuple)
              end

              it "triggers the on_tuple_update event for the CompositeTuple" do
                updated = []
                join.on_tuple_update do |tuple, attribute, old_value, new_value|
                  updated.push [tuple, attribute, old_value, new_value]
                end
                old_value = photo[:name]
                new_value = "A great naked show part 2"
                photo[:name] = new_value
                updated.should == [[compound_tuple, photos_set[:name], old_value, new_value]]
              end

              it "does not trigger the on_insert or on_delete event" do
                join.on_insert do |tuple|
                  raise "Dont call me"
                end
                join.on_delete do |tuple|
                  raise "Dont call me"
                end
                photo[:name] = "A great naked show part 3"
              end
            end
          end
        end

        context "when a Tuple deleted from #operand_1" do
          attr_reader :user, :tuple_class
          context "is a member of a compound Tuple that matches the #predicate" do
            attr_reader :photo, :compound_tuple
            before do
              @tuple_class = CompositeTuple::Base
              @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")
              @user = User.create(:id => 100, :name => "Brian")
              @compound_tuple = join.detect {|tuple| tuple[users_set] == user && tuple[photos_set] == photo}
              predicate.eval(compound_tuple).should be_true
              join.should include(compound_tuple)
            end

            it "deletes the compound Tuple from the result of #tuples" do
              users_set.delete(user)
              join.should_not include(compound_tuple)
            end

            it "triggers the on_delete event" do
              deleted = nil
              join.on_delete do |deleted_tuple|
                deleted = deleted_tuple
              end

              users_set.delete(user)
              deleted.should == compound_tuple
            end

            it "#releases the Tuple" do
              compound_tuple = join.find(user.id)
              compound_tuple.should be_retained_by(join)
              users_set.delete(user)
              compound_tuple.should_not be_retained_by(join)
            end
          end

          context "is not a member of a compound Tuple that matches the #predicate" do
            before do
              @tuple_class = CompositeTuple::Base
              @user = User.create(:id => 100, :name => "Brian")
              join.any? do |compound_tuple|
                compound_tuple[users_set] == user
              end.should be_false
            end

            it "does not delete a compound Tuple from the result of #tuples" do
              lambda do
                users_set.delete(user)
              end.should_not change{join.length}
            end

            it "does not trigger the on_delete event" do
              join.on_delete do |deleted_tuple|
                raise "I should not be invoked"
              end
              users_set.delete(user)
            end
          end
        end

        context "when a Tuple deleted from #operand_2" do
          attr_reader :photo, :tuple_class
          context "is a member of a compound Tuple that matches the #predicate" do
            attr_reader :user, :compound_tuple
            before do
              @tuple_class = CompositeTuple::Base
              @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")
              @user = User.create(:id => 100, :name => "Brian")
              @compound_tuple = join.detect {|tuple| tuple[users_set] == user && tuple[photos_set] == photo}
              predicate.eval(compound_tuple).should be_true
              join.should include(compound_tuple)
            end

            it "deletes the compound Tuple from the result of #tuples" do
              photos_set.delete(photo)
              join.should_not include(compound_tuple)
            end

            it "triggers the on_delete event" do
              deleted = nil
              join.on_delete do |deleted_tuple|
                deleted = deleted_tuple
              end

              photos_set.delete(photo)
              deleted.should == compound_tuple
            end

            it "#releases the Tuple" do
              compound_tuple = join.where(photos_set[:id].eq(photo[:id])).first
              compound_tuple.should be_retained_by(join)
              photos_set.delete(photo)
              compound_tuple.should_not be_retained_by(join)
            end
          end

          context "is not a member of a compound Tuple that matches the #predicate" do
            before do
              @tuple_class = CompositeTuple::Base
              @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")
              join.any? do |compound_tuple|
                compound_tuple[photos_set] == photo
              end.should be_false
            end

            it "does not delete a compound Tuple from the result of #tuples" do
              lambda do
                photos_set.delete(photo)
              end.should_not change{join.length}
            end

            it "does not trigger the on_delete event" do
              join.on_delete do |deleted_tuple|
                raise "I should not be invoked"
              end
              photos_set.delete(photo)
            end
          end
        end

        describe "#after_last_release" do
          before do
            publicize join, :subscriptions
            publicize operand_1, :insert_subscription_node, :delete_subscription_node, :tuple_update_subscription_node
            publicize operand_2, :insert_subscription_node, :delete_subscription_node, :tuple_update_subscription_node
          end

          it "unsubscribes from and releases its operands" do
            operand_1.should be_retained_by(join)
            operand_2.should be_retained_by(join)
            join.subscriptions.should_not be_empty

            join.should be_subscribed_to(operand_1.insert_subscription_node)
            join.should be_subscribed_to(operand_1.delete_subscription_node)
            join.should be_subscribed_to(operand_1.tuple_update_subscription_node)

            join.should be_subscribed_to(operand_2.insert_subscription_node)
            join.should be_subscribed_to(operand_2.delete_subscription_node)
            join.should be_subscribed_to(operand_2.tuple_update_subscription_node)

            mock.proxy(join).after_last_release
            join.released_by(retainer)

            operand_1.should_not be_retained_by(join)
            operand_2.should_not be_retained_by(join)

            join.should_not be_subscribed_to(operand_1.insert_subscription_node)
            join.should_not be_subscribed_to(operand_1.delete_subscription_node)
            join.should_not be_subscribed_to(operand_1.tuple_update_subscription_node)

            join.should_not be_subscribed_to(operand_2.insert_subscription_node)
            join.should_not be_subscribed_to(operand_2.delete_subscription_node)
            join.should_not be_subscribed_to(operand_2.tuple_update_subscription_node)
          end

          it "releases its #predicate" do
            predicate.should be_retained_by(join)
            mock.proxy(join).after_last_release
            join.released_by(retainer)
            predicate.should_not be_retained_by(join)
          end
        end

        describe "#find_compound_tuple" do
          attr_reader :photo, :user

          context "when #tuples contains a CompositeTuple that contains both of the arguments" do
            before do
              @user = User.create(:id => 100, :name => "Brian")
              @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")

              join.tuples.any? do |compound_tuple|
                compound_tuple[users_set] == user &&
                  compound_tuple[photos_set] == photo
              end.should be_true
            end

            it "returns the CompositeTuple" do
              compound_tuple = join.send(:find_compound_tuple, user, photo)
              compound_tuple[users_set].should == user
              compound_tuple[photos_set].should == photo
            end
          end

          context "when #tuples only contains a CompositeTuple that contains the first argument" do
            before do
              @user = User.find(1)
              @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")

              join.tuples.any? do |compound_tuple|
                compound_tuple[users_set] == user &&
                  compound_tuple[photos_set] == photo
              end.should be_false

              join.tuples.any? do |compound_tuple|
                compound_tuple[users_set] == user
              end.should be_true
            end


            it "returns nil" do
              join.send(:find_compound_tuple, user, photo).should be_nil
            end
          end

          context "when #tuples only contains a CompositeTuple that contains the second argument" do
            before do
              @user = User.create(:id => 100, :name => "Brian")
              @photo = Photo.find(1)

              join.tuples.any? do |compound_tuple|
                compound_tuple[users_set] == user &&
                  compound_tuple[photos_set] == photo
              end.should be_false

              join.tuples.any? do |compound_tuple|
                compound_tuple[photos_set] == photo
              end.should be_true
            end

            it "returns nil" do
              join.send(:find_compound_tuple, user, photo).should be_nil
            end
          end
        end
      end

      context "when not #retained?" do
        describe "#after_first_retain" do
          it "retains the operands and #predicate" do
            mock.proxy(join).after_first_retain
            
            join.operand_1.should_not be_retained_by(join)
            join.operand_2.should_not be_retained_by(join)
            join.predicate.should_not be_retained_by(join)

            join.retained_by(Object.new)
            join.operand_1.should be_retained_by(join)
            join.operand_2.should be_retained_by(join)
            join.predicate.should be_retained_by(join)
          end
        end

        describe "#tuples" do
          it "returns all tuples in its operands for which its predicate returns true" do
            tuples = join
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
end
