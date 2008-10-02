require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Relations
    describe SetProjection do
      attr_reader :operand, :projection, :projected_set
      before do
        @operand = users_set.join(photos_set).on(photos_set[:user_id].eq(users_set[:id]))
        @projected_set = users_set
        @projection = SetProjection.new(operand, projected_set)
      end

      describe "#initialize" do
        it "sets #operand and #projected_set" do
          projection.operand.should == operand
          projection.projected_set.should == projected_set
        end
      end

      describe "#tuple_class" do
        it "delegates to #projected_set" do
          projection.tuple_class.should == projected_set.tuple_class
        end
      end

      describe "#to_sql" do
        it "returns select attributes from operand" do
          projection.to_sql.should be_like("
            SELECT DISTINCT `users`.`id`, `users`.`name`, `users`.`hobby`, `users`.`team_id`, `users`.`developer`
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

      describe "#push" do
        it "delegates to #operand" do
          origin.connection[:photos].delete
          origin.connection[:users].delete
          
          mock.proxy(operand).push(origin)
          origin.fetch(projection).should be_empty
          projection.push(origin)
          origin.fetch(projection).should == projection.tuples
        end
      end

      describe "#set" do
        it "returns #projected_set" do
          projection.set.should == projected_set
        end
      end

      describe "#composed_sets" do
        it "delegates to #operand " do
          projection.composed_sets.should == operand.composed_sets
        end
      end

      describe "#attribute" do
        context "when the #projected_set.has_attribute? is true for the given Attribute" do
          it "delegates to #projected_set" do
            projected_set.should have_attribute(:id)
            projected_set_attribute = projected_set.attribute(:id)
            mock.proxy(projected_set).attribute(:id)
            projection.attribute(:id).should == projected_set_attribute
          end
        end

        context "when the #projected_set.has_attribute? is false and the #operand.has_attribute? is true for the given Attribute" do
          it "delegates to #projected_set which raises an ArgumentError" do
            operand.should have_attribute(:user_id)
            projected_set.should_not have_attribute(:user_id)
            mock.proxy(projected_set).attribute(:user_id)

            lambda do
              projection.attribute(:user_id).should == projected_set_attribute
            end.should raise_error(ArgumentError)
          end
        end
      end

      describe "#has_attribute?" do
        context "when the #projected_set.has_attribute? is true for the given Attribute" do
          it "delegates to the #projected_set" do
            projected_set.should have_attribute(:id)
            mock.proxy(projected_set).has_attribute?(:id)

            projection.should have_attribute(:id)
          end
        end

        context "when the #projected_set.has_attribute? is false and the #operand.has_attribute? is true for the given Attribute" do
          it "delegates to #projected_set" do
            operand.should have_attribute(:user_id)
            projected_set.should_not have_attribute(:user_id)
            mock.proxy(projected_set).has_attribute?(:user_id)

            projection.should_not have_attribute(:user_id)
          end
        end
      end

      context "when #retained?" do
        attr_reader :retainer
        before do
          @retainer = Object.new
          projection.retain_with(retainer)
        end

        describe "#merge" do
          it "calls #merge on the #projected_set" do
            tuple = User.new(:id => 100, :name => "Jan")
            mock.proxy(projected_set).merge([tuple])
            projected_set.should_not include(tuple)
            projection.merge([tuple])
            projected_set.should include(tuple)
          end
        end

        context "when the a Tuple is inserted into the #operand" do
          attr_reader :user
          context "when the inserted Tuple restricted by #projected_set is not in the SetProjection" do
            before do
              @user = User.create(:id => 100, :name => "Brian")
            end

            it "inserts the Tuple restricted by #projected_set into itself" do
              projection.tuples.should_not include(user)
              lambda do
                Photo.create(:id => 100, :user_id => user[:id], :name => "Photo 100")
              end.should change{projection.tuples.length}.by(1)
              projection.tuples.should include(user)
            end

            it "triggers the on_insert event" do
              inserted = nil
              projection.on_insert(retainer) do |tuple|
                inserted = tuple
              end
              Photo.create(:id => 100, :user_id => user[:id], :name => "Photo 100")

              inserted.should == user
            end
          end

          context "when the inserted Tuple restricted by #projected_set is in the SetProjection" do
            before do
              @user = projection.tuples.first
              projection.tuples.should include(user)
            end

            it "does not insert the Tuple restricted by #projected_set" do
              lambda do
                Photo.create(:id => 100, :user_id => user[:id], :name => "Photo 100")
              end.should_not change{projection.tuples.length}
            end

            it "does not trigger the on_insert event" do
              projection.on_insert(retainer) do |tuple|
                raise "I should not be called"
              end

              Photo.create(:id => 100, :user_id => user[:id], :name => "Photo 100")
            end
          end
        end

        context "when a Tuple is deleted from the #operand" do
          attr_reader :user
          
          context "when the deleted Tuple restricted by #projected_set is in the SetProjection" do
            context "and no other identical Tuple restricted by #projected_set is in the operand" do
              attr_reader :photo
              before do
                @user = User.create(:id => 100, :name => "Brian")
                @photo = Photo.create(:id => 100, :user_id => user[:id], :name => "Photo 100")
                projection.tuples.should include(user)
              end

              it "removes the Tuple restricted by #projected_set" do
                lambda do
                  users_set.delete(user)
                end.should change{projection.tuples.length}.by(-1)
                projection.tuples.should_not include(user)
              end

              it "triggers the on_delete event with the deleted Tuple restricted by #projected_set" do
                deleted = nil
                projection.on_delete(retainer) do |tuple|
                  deleted = tuple
                end
                users_set.delete(user)

                deleted.should == user
              end
            end

            context "and another identical Tuple restricted by #projected_set is in the operand" do
              attr_reader :photo_1, :photo_2
              before do
                @user = User.create(:id => 100, :name => "Brian")
                @photo_1 = Photo.create(:id => 100, :user_id => user[:id], :name => "Photo 100")
                @photo_2 = Photo.create(:id => 101, :user_id => user[:id], :name => "Photo 101")
                projection.tuples.should include(user)
              end

              it "does not remove the Tuple restricted by #projected_set from the Tuples returned by #tuples" do
                lambda do
                  photos_set.delete(photo_1)
                end.should_not change{projection.tuples.length}
                projection.tuples.should include(user)
              end

              it "does not trigger the on_delete event" do
                projection.on_delete(retainer) do |tuple|
                  raise "I should not be invoked"
                end
                photos_set.delete(photo_1)
              end

            end
          end

          context "when the deleted Tuple restricted by #projected_set is not in the SetProjection" do
            before do
              @user = User.create(:id => 100, :name => "Brian")
              projection.tuples.should_not include(user)
            end

            it "does not remove the Tuple restricted by #projected_set" do
              lambda do
                users_set.delete(user)
              end.should_not change{projection.tuples.length}
              projection.tuples.should_not include(user)
            end

            it "does not trigger the on_delete event with the Tuple restricted by #projected_set" do
              projection.on_delete(retainer) do |tuple|
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

          context "and the updated PrimitiveAttribute is in #projected_set" do
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
              projection.on_tuple_update(retainer) do |tuple, attribute, old_value, new_value|
                on_tuple_update_arguments.push [tuple, attribute, old_value, new_value]
              end
              operand_projected_tuple[:name] = new_value
              on_tuple_update_arguments.should == [[projected_tuple, attribute, old_value, new_value]]
            end

            context "when the same PrimitiveAttribute on a different Tuple is subsequently updated from the same old value to the same new value" do
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
                projection.on_tuple_update(retainer) do |tuple, attribute, old_value, new_value|
                  on_tuple_update_arguments.push [tuple, attribute, old_value, new_value]
                end

                another_projected_tuple[:name] = new_value
                on_tuple_update_arguments.should == [
                  [another_projected_tuple, attribute, old_value, new_value]
                ]
              end
            end

            context "when a different PrimitiveAttribute on the same Tuple is subsequently updated from the same old value to the same new value" do
              before do
                operand_projected_tuple[:hobby] = old_value
                operand_projected_tuple[:name] = new_value
              end

              it "triggers #on_tuple_update subscriptions once" do
                on_tuple_update_arguments = []
                projection.on_tuple_update(retainer) do |tuple, attribute, old_value, new_value|
                  on_tuple_update_arguments.push [tuple, attribute, old_value, new_value]
                end

                operand_projected_tuple[:hobby] = new_value
                on_tuple_update_arguments.should == [
                  [projected_tuple, users_set[:hobby], old_value, new_value]
                ]
              end
            end
          end

          context "and the updated PrimitiveAttribute is not in #projected_set" do
            attr_reader :photo
            before do
              @photo = operand_compound_tuple[photos_set]
            end

            it "does not trigger #on_tuple_update subscriptions" do
              projection.on_tuple_update(retainer) do |tuple, attribute, old_value, new_value|
                raise "Don't taze me bro"
              end
              photo[:name] = "Freak show"
            end
          end
        end
      end

      context "when not #retained?" do
        describe "#tuples" do
          context "when #projected_set is one of the immediate operands of #operand" do
            it "returns the unique set of PrimitiveTuples corresponding to #projected_set from the #operand" do
              projection.tuples.should == operand.tuples.map {|tuple| tuple[projected_set]}.uniq
            end
          end

          context "when #projected_set is an operand of an operand of #operand" do
            before do
              @projected_set = cameras_set
              @operand = operand.join(cameras_set).on(photos_set[:camera_id].eq(cameras_set[:id]))
              @projection = operand.project(projected_set)
            end

            it "returns the unique set of PrimitiveTuples corresponding to #projected_set from the #operand" do
              projection.tuples.should == operand.tuples.map {|tuple| tuple[projected_set]}.uniq
            end
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
