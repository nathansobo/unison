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
      end

      describe "#to_sql" do
        it "returns select attributes from operand" do
          projection.to_sql.should be_like("
            SELECT `users`.`id`, `users`.`name`, `users`.`hobby`
            FROM `users`
            INNER JOIN `photos`
            ON `photos`.`user_id` = `users`.`id`"
          )
        end
      end

      describe "#to_arel" do
        it "returns an Arel representation of the relation" do
          projection.to_arel.should == Arel::Project.new(
            operand.to_arel,
            *users_set.to_arel.attributes
          )
        end
      end

      context "after #retain has been called" do
        before do
          projection.retain(Object.new)
        end

        describe "#merge" do
          it "calls #merge on the Set that is the source of #attributes" do
            tuple = User.new(:id => 100, :name => "Jan")
            mock.proxy(attributes).merge([tuple])
            attributes.should_not include(tuple)
            projection.merge([tuple])
            attributes.should include(tuple)
          end
        end

        context "when the a Tuple is inserted into the #operand" do
          attr_reader :user
          context "when the inserted Tuple restricted by #attributes is not in the Projection" do
            before do
              @user = User.create(:id => 100, :name => "Brian")
            end

            it "inserts the Tuple restricted by #attributes into itself" do
              projection.tuples.should_not include(user)
              lambda do
                Photo.create(:id => 100, :user_id => user[:id], :name => "Photo 100")
              end.should change{projection.tuples.length}.by(1)
              projection.tuples.should include(user)
            end

            it "invokes #on_insert callbacks" do
              inserted = nil
              projection.on_insert do |tuple|
                inserted = tuple
              end
              Photo.create(:id => 100, :user_id => user[:id], :name => "Photo 100")

              inserted.should == user
            end
          end

          context "when the inserted Tuple restricted by #attributes is in the Projection" do
            before do
              @user = projection.tuples.first
              projection.tuples.should include(user)
            end

            it "does not insert the Tuple restricted by #attributes" do
              lambda do
                Photo.create(:id => 100, :user_id => user[:id], :name => "Photo 100")
              end.should_not change{projection.tuples.length}
            end

            it "does not invoke #on_insert callbacks" do
              projection.on_insert do |tuple|
                raise "I should not be called"
              end

              Photo.create(:id => 100, :user_id => user[:id], :name => "Photo 100")
            end
          end
        end

        context "when a Tuple is deleted from the #operand" do
          attr_reader :user
          
          context "when the deleted Tuple restricted by #attributes is in the Projection" do
            context "and no other identical Tuple restricted by #attributes is in the operand" do
              attr_reader :photo
              before do
                @user = User.create(:id => 100, :name => "Brian")
                @photo = Photo.create(:id => 100, :user_id => user[:id], :name => "Photo 100")
                projection.tuples.should include(user)
              end

              it "removes the Tuple restricted by #attributes" do
                lambda do
                  users_set.delete(user)
                end.should change{projection.tuples.length}.by(-1)
                projection.tuples.should_not include(user)
              end

              it "invokes #on_delete callbacks with the deleted Tuple restricted by #attributes" do
                deleted = nil
                projection.on_delete do |tuple|
                  deleted = tuple
                end
                users_set.delete(user)

                deleted.should == user
              end
            end

            context "and another identical Tuple restricted by #attributes is in the operand" do
              attr_reader :photo_1, :photo_2
              before do
                @user = User.create(:id => 100, :name => "Brian")
                @photo_1 = Photo.create(:id => 100, :user_id => user[:id], :name => "Photo 100")
                @photo_2 = Photo.create(:id => 101, :user_id => user[:id], :name => "Photo 101")
                projection.tuples.should include(user)
              end

              it "does not remove the Tuple restricted by #attributes from the Tuples returned by #tuples" do
                lambda do
                  photos_set.delete(photo_1)
                end.should_not change{projection.tuples.length}
                projection.tuples.should include(user)
              end

              it "does not invoke #on_delete callbacks" do
                projection.on_delete do |tuple|
                  raise "I should not be invoked"
                end
                photos_set.delete(photo_1)
              end

            end
          end

          context "when the deleted Tuple restricted by #attributes is not in the Projection" do
            before do
              @user = User.create(:id => 100, :name => "Brian")
              projection.tuples.should_not include(user)
            end

            it "does not remove the Tuple restricted by #attributes" do
              lambda do
                users_set.delete(user)
              end.should_not change{projection.tuples.length}
              projection.tuples.should_not include(user)
            end

            it "does not invoke #on_delete callbacks with the Tuple restricted by #attributes" do
              projection.on_delete do |tuple|
                raise "I should not be invoked"
              end
              users_set.delete(user)
            end
          end
        end

        context "when a Tuple is updated in the #operand" do
          attr_reader :operand_compound_tuple, :operand_projected_tuple, :projected_tuple, :attribute
          before do
            @operand_compound_tuple = operand.tuples.first
            @operand_projected_tuple = operand_compound_tuple[users_set]
            @projected_tuple = projection.tuples.find do |tuple|
              tuple == operand_projected_tuple
            end
            @attribute = users_set[:name]
          end

          context "and the updated Attribute is in #attributes" do
            attr_reader :old_value, :new_value
            before do
              operand.tuples.select do |tuple|
                tuple[users_set] == operand_projected_tuple
              end.size.should be > 1
              @old_value = operand_projected_tuple[:name]
              @new_value = "Joe"
            end

            it "updates the projected Tuple's value in #tuples" do
              operand_projected_tuple[:name] = new_value
              projected_tuple[:name].should == "Joe"
            end

            it "triggers #on_tuple_update subscriptions once" do
              on_tuple_update_arguments = []
              projection.on_tuple_update do |tuple, attribute, old_value, new_value|
                on_tuple_update_arguments.push [tuple, attribute, old_value, new_value]
              end
              operand_projected_tuple[:name] = new_value
              on_tuple_update_arguments.should == [[projected_tuple, attribute, old_value, new_value]]
            end

            context "when the same Attribute on a different Tuple is subsequently updated from the same old value to the same new value" do
              attr_reader :another_compound_tuple, :another_projected_tuple
              before do
                @another_compound_tuple = operand.tuples.find do |tuple|
                  tuple[users_set] != projected_tuple
                end
                @another_projected_tuple = another_compound_tuple[users_set]
                another_projected_tuple.should_not == projected_tuple

                another_projected_tuple[:name] = old_value
                projected_tuple[:name] = new_value
              end

              it "triggers #on_tuple_update subscriptions once" do
                on_tuple_update_arguments = []
                projection.on_tuple_update do |tuple, attribute, old_value, new_value|
                  on_tuple_update_arguments.push [tuple, attribute, old_value, new_value]
                end

                another_projected_tuple[:name] = new_value
                on_tuple_update_arguments.should == [
                  [another_projected_tuple, attribute, old_value, new_value]
                ]
              end
            end

            context "when a different Attribute on the same Tuple is subsequently updated from the same old value to the same new value" do
              before do
                operand_projected_tuple[:hobby] = old_value
                operand_projected_tuple[:name] = new_value
              end

              it "triggers #on_tuple_update subscriptions once" do
                on_tuple_update_arguments = []
                projection.on_tuple_update do |tuple, attribute, old_value, new_value|
                  on_tuple_update_arguments.push [tuple, attribute, old_value, new_value]
                end

                operand_projected_tuple[:hobby] = new_value
                on_tuple_update_arguments.should == [
                  [projected_tuple, users_set[:hobby], old_value, new_value]
                ]
              end
            end
          end

          context "and the updated Attribute is not in #attributes" do
            attr_reader :photo
            before do
              @photo = operand_compound_tuple[photos_set]
            end

            it "does not trigger #on_tuple_update subscriptions" do
              projection.on_tuple_update do |tuple, attribute, old_value, new_value|
                raise "Dont call me"
              end
              photo[:name] = "Freak show"
            end
          end
        end

        describe "#after_last_release" do
          before do
            projection.retain(Object.new)
          end

          it "unsubscribes from and releases its #operand" do
            operand.extend AddSubscriptionsMethodToRelation
            operand.should be_retained_by(projection)

            projection.send(:operand_subscriptions).should_not be_empty
            projection.send(:operand_subscriptions).each do |subscription|
              operand.subscriptions.should include(subscription)
            end

            projection.send(:after_last_release)

            operand.should_not be_retained_by(projection)
            projection.send(:operand_subscriptions).should_not be_empty
            projection.send(:operand_subscriptions).each do |subscription|
              operand.subscriptions.should_not include(subscription)
            end
          end
        end
      end

      context "before #retain has been called" do
        describe "#retain" do
          it "retains its #operand" do
            operand.should_not be_retained_by(projection)
            projection.retain Object.new
            operand.should be_retained_by(projection)
          end
        end

        describe "#tuples" do
          it "returns a set restricted to #attributes from the #operand" do
            projection.tuples.should == operand.tuples.map {|tuple| tuple[attributes]}.uniq
          end
        end

        describe "#merge" do
          it "raises an Exception" do
            lambda do
              projection.merge([Photo.new(:id => 100, :user_id => 1, :name => "Photo 100")])
            end.should raise_error
          end
        end
      end
    end
  end
end
