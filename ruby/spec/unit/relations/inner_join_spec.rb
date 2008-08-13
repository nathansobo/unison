require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

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
            SELECT `users`.`id`, `users`.`name`, `users`.`hobby`, `photos`.`id`, `photos`.`user_id`, `photos`.`name`
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

      describe "#set" do
        it "raises a NotImplementedError" do
          lambda do
            join.set
          end.should raise_error(NotImplementedError)
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

      context "after #retain has been called" do
        before do
          join.retain(Object.new)
        end

        context "when a Tuple inserted into #operand_1" do
          context "when the inserted Tuple creates a compound Tuple that matches the #predicate" do
            attr_reader :photo, :user, :tuple_class, :expected_tuple
            before do
              @tuple_class = CompoundTuple::Base
              @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")
              @user = User.new(:id => 100, :name => "Brian")
              @expected_tuple = tuple_class.new(user, photo)
              predicate.eval(expected_tuple).should be_true
            end

            it "adds the CompoundTuple to the result of #tuples" do
              join.should_not include(expected_tuple)
              users_set.insert(user)
              join.should include(expected_tuple)
            end

            it "invokes the #on_insert event" do
              inserted = nil
              join.on_insert do |tuple|
                inserted = tuple
              end
              users_set.insert(user)

              predicate.eval(inserted).should be_true
              inserted[photos_set].should == photo
              inserted[users_set].should == user
            end

            it "retains the CompoundTuple" do
              join.find(user.id).should be_nil
              users_set.insert(user)
              join.find(user.id).tuples.first.should be_retained_by(join)
            end
          end

          context "when the inserted Tuple creates a compound Tuple that does not match the #predicate" do
            attr_reader :photo, :user, :tuple_class, :expected_tuple
            before do
              @tuple_class = CompoundTuple::Base
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

            it "does not invoke the #on_insert callback" do
              join.on_insert do |tuple|
                raise "I should not be invoked"
              end
              users_set.insert(user)
            end

            it "does not retain the CompoundTuple" do
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
              @tuple_class = CompoundTuple::Base
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

            it "invokes the #on_insert event" do
              inserted = nil
              join.on_insert do |tuple|
                inserted = tuple
              end
              photos_set.insert(photo)

              predicate.eval(inserted).should be_true
              inserted[photos_set].should == photo
              inserted[users_set].should == user
            end
            
            it "retains the CompoundTuple" do
              join.where(photos_set[:id].eq(photo[:id])).should be_empty
              photos_set.insert(photo)
              join.where(photos_set[:id].eq(photo[:id])).first.should be_retained_by(join)
            end
          end

          context "when the inserted Tuple creates a compound Tuple that does not match the #predicate" do
            attr_reader :photo, :user, :tuple_class, :expected_tuple
            before do
              @tuple_class = CompoundTuple::Base
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

            it "does not invoke the #on_insert callback" do
              join.on_insert do |tuple|
                raise "I should not be invoked"
              end
              photos_set.insert(photo)
            end

            it "does not retain the CompoundTuple" do
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
              @expected_compound_tuple = CompoundTuple::Base.new(user, photo)
            end

            context "when the update causes a compound Tuple to match the #predicate" do
              it "adds that compound Tuple to the result of #tuples" do
                join.should_not include(expected_compound_tuple)
                user[:id] = photo[:user_id]
                join.should include(expected_compound_tuple)
              end

              it "invokes the #on_insert event" do
                inserted = nil
                join.on_insert do |tuple|
                  inserted = tuple
                end
                user[:id] = photo[:user_id]

                predicate.eval(inserted).should be_true
                inserted[photos_set].should == photo
                inserted[users_set].should == user
              end

              it "retains the CompoundTuple" do
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

              it "does not invoke the #on_insert event" do
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

              it "invokes the on_delete event" do
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

              it "releases the CompoundTuple" do
                compound_tuple = join.find(user.id).tuples.first
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

              it "invokes the #on_tuple_update event for the compound Tuple" do
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

              it "does not invoke the #on_insert or #on_delete event" do
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
              @expected_compound_tuple = CompoundTuple::Base.new(user, photo)
            end

            context "when the update causes a compound Tuple to match the #predicate" do
              it "adds that compound Tuple to the result of #tuples" do
                join.should_not include(expected_compound_tuple)
                photo[:user_id] = user[:id]
                join.should include(expected_compound_tuple)
              end

              it "invokes the #on_insert event" do
                inserted = nil
                join.on_insert do |tuple|
                  inserted = tuple
                end
                photo[:user_id] = user[:id]

                predicate.eval(inserted).should be_true
                inserted[photos_set].should == photo
                inserted[users_set].should == user
              end

              it "retains the CompoundTuple" do
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

              it "does not invoke the #on_insert event" do
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

              it "invokes the on_delete event" do
                deleted = []
                join.on_delete do |tuple|
                  deleted.push tuple
                end
                photo[:user_id] = 100
                deleted.should == [compound_tuple]
              end

              it "releases the CompoundTuple" do
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

              it "invokes the #on_tuple_update event for the compound Tuple" do
                updated = []
                join.on_tuple_update do |tuple, attribute, old_value, new_value|
                  updated.push [tuple, attribute, old_value, new_value]
                end
                old_value = photo[:name]
                new_value = "A great naked show part 2"
                photo[:name] = new_value
                updated.should == [[compound_tuple, photos_set[:name], old_value, new_value]]
              end

              it "does not invoke the #on_insert or #on_delete event" do
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
              @tuple_class = CompoundTuple::Base
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

            it "invokes the #on_delete callback" do
              deleted = nil
              join.on_delete do |deleted_tuple|
                deleted = deleted_tuple
              end

              users_set.delete(user)
              deleted.should == compound_tuple
            end

            it "#releases the Tuple" do
              compound_tuple = join.find(user.id).tuples.first
              compound_tuple.should be_retained_by(join)
              users_set.delete(user)
              compound_tuple.should_not be_retained_by(join)
            end
          end

          context "is not a member of a compound Tuple that matches the #predicate" do
            before do
              @tuple_class = CompoundTuple::Base
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

            it "does not invoke the #on_delete callback" do
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
              @tuple_class = CompoundTuple::Base
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

            it "invokes the #on_delete callback" do
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
              @tuple_class = CompoundTuple::Base
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

            it "does not invoke the #on_delete callback" do
              join.on_delete do |deleted_tuple|
                raise "I should not be invoked"
              end
              photos_set.delete(photo)
            end
          end
        end

        describe "#after_last_release" do
          before do
            join.retain(Object.new)
          end

          it "unsubscribes from and releases its operands" do
            operand_1.extend AddSubscriptionsMethodToRelation
            operand_2.extend AddSubscriptionsMethodToRelation

            operand_1.should be_retained_by(join)
            operand_2.should be_retained_by(join)
            join.send(:operand_1_subscriptions).should_not be_empty
            join.send(:operand_1_subscriptions).each do |subscription|
              operand_1.subscriptions.should include(subscription)
            end
            join.send(:operand_2_subscriptions).should_not be_empty
            join.send(:operand_2_subscriptions).each do |subscription|
              operand_2.subscriptions.should include(subscription)
            end

            join.send(:after_last_release)

            operand_1.should_not be_retained_by(join)
            operand_2.should_not be_retained_by(join)
            join.send(:operand_1_subscriptions).should_not be_empty
            join.send(:operand_1_subscriptions).each do |subscription|
              operand_1.subscriptions.should_not include(subscription)
            end
            join.send(:operand_2_subscriptions).should_not be_empty
            join.send(:operand_2_subscriptions).each do |subscription|
              operand_2.subscriptions.should_not include(subscription)
            end
          end

          it "releases its #predicate" do
            predicate.should be_retained_by(join)
            join.send(:after_last_release)
            predicate.should_not be_retained_by(join)
          end
        end

        describe "#find_compound_tuple" do
          attr_reader :photo, :user

          context "when #tuples contains a CompoundTuple that contains both of the arguments" do
            before do
              @user = User.create(:id => 100, :name => "Brian")
              @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")

              join.tuples.any? do |compound_tuple|
                compound_tuple[users_set] == user &&
                  compound_tuple[photos_set] == photo
              end.should be_true
            end

            it "returns the CompoundTuple" do
              compound_tuple = join.send(:find_compound_tuple, user, photo)
              compound_tuple[users_set].should == user
              compound_tuple[photos_set].should == photo
            end
          end

          context "when #tuples only contains a CompoundTuple that contains the first argument" do
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

          context "when #tuples only contains a CompoundTuple that contains the second argument" do
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

      context "before #retain has been called" do
        describe "#retain" do
          it "retains the operands and #predicate" do
            join.operand_1.should_not be_retained_by(join)
            join.operand_2.should_not be_retained_by(join)
            join.predicate.should_not be_retained_by(join)

            join.retain(Object.new)
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
