require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Relations
    describe AttributesProjection do
      attr_reader :operand, :projection, :projected_attributes
      before do
        @operand = users_set
        @projection = AttributesProjection.new(operand, projected_attributes)
      end

      def projected_attributes
        @projected_attributes ||= [User[:id], User[:name], User[:hobby]]
      end

      describe "#initialize" do
        context "when the given projected attributes are instances of Attribute" do
          it "sets #operand and #projected_attributes" do
            projection.operand.should == operand
            projection.projected_attributes.should == projected_attributes
          end
        end

        context "when any of the given projected attributes are Symbols" do
          def projected_attributes
            @projected_attributes ||= [User[:id], :name, :hobby]
          end

          it "translates the Symbols in the given projected attributes into Attributes" do
            projection.projected_attributes.should == [User[:id], User[:name], User[:hobby]]
          end
        end
      end

      describe "#attribute" do
        context "when #projected_attributes includes an Attribute with the given name" do
          it "returns the Attribute with the given name" do
            attribute = User[:id]
            projected_attributes.should include(attribute)
            projection.attribute(:id).should == attribute
          end
        end

        context "when #projected_attributes does not include an Attribute by the given name but the #operand does" do
          it "raises an ArgumentError" do
            attribute = User[:team_id]
            operand.should have_attribute(:team_id)
            projected_attributes.should_not include(attribute)

            lambda do
              projection.attribute(:team_id)
            end.should raise_error(ArgumentError)
          end
        end
      end

      describe "#has_attribute?" do
        context "when #projected_attributes includes an Attribute with the given name" do
          it "returns true" do
            attribute = User[:id]
            projected_attributes.should include(attribute)
            projection.should have_attribute(:id)
          end
        end

        context "when #projected_attributes does not include an Attribute by the given name but the #operand does" do
          it "returns false" do
            attribute = User[:team_id]
            operand.should have_attribute(:team_id)
            projected_attributes.should_not include(attribute)
            projection.should_not have_attribute(:team_id)
          end
        end
      end

      describe "#initial_read" do
        before do
          publicize projection, :initial_read
        end

        it "returns an Array of ProjectedTuples corresponding to every Tuple in the #operand" do
          initial_read = projection.initial_read
          operand.tuples.each do |tuple|
            initial_read.select do |projected_tuple|
              projected_tuple[:id] == tuple[:id] &&
              projected_tuple[:name] == tuple[:name] &&
              projected_tuple[:hobby] == tuple[:hobby]
            end.length.should == 1
          end
        end
      end

      context "when #retained?" do
        attr_reader :retainer
        before do
          @retainer = Object.new
          projection.retain_with(retainer)
        end

        context "when the a Tuple is inserted into the #operand" do
          attr_reader :user

          context "when the projection of the inserted Tuple is unique" do
            attr_reader :attributes
            before do
              User.find(Unison.and(
                User[:id].eq("brian"),
                User[:name].eq("Brian"),
                User[:hobby].eq("Chess")
              )).should be_nil

              @attributes = {
                :id => "brian",
                :name => "Brian",
                :hobby => "Chess"
              }
            end

            it "inserts a ProjectedTuple with the #projected_attributes into itself" do
              pending "not yet implemented"
              projection.find(User[:id].eq(attributes[:id])).should be_nil

              user = nil
              lambda do
                user = User.create(attributes)
              end.should change{projection.tuples.length}.by(1)

              projected_tuple = projection.find(User[:id].eq(attributes[:id]))
              projected_tuple[:id].should == user[:id]
              projected_tuple[:name].should == user[:name]
              projected_tuple[:hobby].should == user[:hobby]
            end
          end


          context "when the inserted Tuple has different values for #projected_attributes than any existing Tuple" do
            before do
              @user = User.create(:id => 100, :name => "Brian")
            end

            it "inserts the Tuple restricted by #projected_set into itself" do
              pending "not yet implemented"
              projection.tuples.should_not include(user)
              lambda do
                Photo.create(:id => 100, :user_id => user[:id], :name => "Photo 100")
              end.should change{projection.tuples.length}.by(1)
              projection.tuples.should include(user)
            end

            it "triggers the on_insert event" do
              pending "not yet implemented"
              inserted = nil
              projection.on_insert(retainer) do |tuple|
                inserted = tuple
              end
              Photo.create(:id => 100, :user_id => user[:id], :name => "Photo 100")

              inserted.should == user
            end
          end

          context "when the projection of the inserted Tuple is not unique" do

          end

#          context "when the inserted Tuple restricted by #projected_set is in the SetProjection" do
#            before do
#              @user = projection.tuples.first
#              projection.tuples.should include(user)
#            end
#
#            it "does not insert the Tuple restricted by #projected_set" do
#              lambda do
#                Photo.create(:id => 100, :user_id => user[:id], :name => "Photo 100")
#              end.should_not change{projection.tuples.length}
#            end
#
#            it "does not trigger the on_insert event" do
#              projection.on_insert(retainer) do |tuple|
#                raise "I should not be called"
#              end
#
#              Photo.create(:id => 100, :user_id => user[:id], :name => "Photo 100")
#            end
#          end
        end
#
#        context "when a Tuple is deleted from the #operand" do
#          attr_reader :user
#
#          context "when the deleted Tuple restricted by #projected_set is in the SetProjection" do
#            context "and no other identical Tuple restricted by #projected_set is in the operand" do
#              attr_reader :photo
#              before do
#                @user = User.create(:id => 100, :name => "Brian")
#                @photo = Photo.create(:id => 100, :user_id => user[:id], :name => "Photo 100")
#                projection.tuples.should include(user)
#              end
#
#              it "removes the Tuple restricted by #projected_set" do
#                lambda do
#                  users_set.delete(user)
#                end.should change{projection.tuples.length}.by(-1)
#                projection.tuples.should_not include(user)
#              end
#
#              it "triggers the on_delete event with the deleted Tuple restricted by #projected_set" do
#                deleted = nil
#                projection.on_delete(retainer) do |tuple|
#                  deleted = tuple
#                end
#                users_set.delete(user)
#
#                deleted.should == user
#              end
#            end
#
#            context "and another identical Tuple restricted by #projected_set is in the operand" do
#              attr_reader :photo_1, :photo_2
#              before do
#                @user = User.create(:id => 100, :name => "Brian")
#                @photo_1 = Photo.create(:id => 100, :user_id => user[:id], :name => "Photo 100")
#                @photo_2 = Photo.create(:id => 101, :user_id => user[:id], :name => "Photo 101")
#                projection.tuples.should include(user)
#              end
#
#              it "does not remove the Tuple restricted by #projected_set from the Tuples returned by #tuples" do
#                lambda do
#                  photos_set.delete(photo_1)
#                end.should_not change{projection.tuples.length}
#                projection.tuples.should include(user)
#              end
#
#              it "does not trigger the on_delete event" do
#                projection.on_delete(retainer) do |tuple|
#                  raise "I should not be invoked"
#                end
#                photos_set.delete(photo_1)
#              end
#
#            end
#          end
#
#          context "when the deleted Tuple restricted by #projected_set is not in the SetProjection" do
#            before do
#              @user = User.create(:id => 100, :name => "Brian")
#              projection.tuples.should_not include(user)
#            end
#
#            it "does not remove the Tuple restricted by #projected_set" do
#              lambda do
#                users_set.delete(user)
#              end.should_not change{projection.tuples.length}
#              projection.tuples.should_not include(user)
#            end
#
#            it "does not trigger the on_delete event with the Tuple restricted by #projected_set" do
#              projection.on_delete(retainer) do |tuple|
#                raise "I should not be invoked"
#              end
#              users_set.delete(user)
#            end
#          end
#        end
#
#        context "when a Tuple is updated in the #operand" do
#          attr_reader :operand_compound_tuple, :operand_projected_tuple, :projected_tuple, :attribute
#          before do
#            @operand_compound_tuple = operand.tuples.first
#            @operand_projected_tuple = operand_compound_tuple[users_set]
#            @projected_tuple = projection.tuples.find do |tuple|
#              tuple == operand_projected_tuple
#            end
#            @attribute = users_set[:name]
#          end
#
#          context "and the updated PrimitiveAttribute is in #projected_set" do
#            attr_reader :old_value, :new_value
#            before do
#              operand.tuples.select do |tuple|
#                tuple[users_set] == operand_projected_tuple
#              end.size.should be > 1
#              @old_value = operand_projected_tuple[:name]
#              @new_value = "Joe"
#            end
#
#            it "updates the projected Tuple's value in #tuples" do
#              operand_projected_tuple[:name] = new_value
#              projected_tuple[:name].should == "Joe"
#            end
#
#            it "triggers #on_tuple_update subscriptions once" do
#              on_tuple_update_arguments = []
#              projection.on_tuple_update(retainer) do |tuple, attribute, old_value, new_value|
#                on_tuple_update_arguments.push [tuple, attribute, old_value, new_value]
#              end
#              operand_projected_tuple[:name] = new_value
#              on_tuple_update_arguments.should == [[projected_tuple, attribute, old_value, new_value]]
#            end
#
#            context "when the same PrimitiveAttribute on a different Tuple is subsequently updated from the same old value to the same new value" do
#              attr_reader :another_compound_tuple, :another_projected_tuple
#              before do
#                @another_compound_tuple = operand.tuples.find do |tuple|
#                  tuple[users_set] != projected_tuple
#                end
#                @another_projected_tuple = another_compound_tuple[users_set]
#                another_projected_tuple.should_not == projected_tuple
#
#                another_projected_tuple[:name] = old_value
#                projected_tuple[:name] = new_value
#              end
#
#              it "triggers #on_tuple_update subscriptions once" do
#                on_tuple_update_arguments = []
#                projection.on_tuple_update(retainer) do |tuple, attribute, old_value, new_value|
#                  on_tuple_update_arguments.push [tuple, attribute, old_value, new_value]
#                end
#
#                another_projected_tuple[:name] = new_value
#                on_tuple_update_arguments.should == [
#                  [another_projected_tuple, attribute, old_value, new_value]
#                ]
#              end
#            end
#
#            context "when a different PrimitiveAttribute on the same Tuple is subsequently updated from the same old value to the same new value" do
#              before do
#                operand_projected_tuple[:hobby] = old_value
#                operand_projected_tuple[:name] = new_value
#              end
#
#              it "triggers #on_tuple_update subscriptions once" do
#                on_tuple_update_arguments = []
#                projection.on_tuple_update(retainer) do |tuple, attribute, old_value, new_value|
#                  on_tuple_update_arguments.push [tuple, attribute, old_value, new_value]
#                end
#
#                operand_projected_tuple[:hobby] = new_value
#                on_tuple_update_arguments.should == [
#                  [projected_tuple, users_set[:hobby], old_value, new_value]
#                ]
#              end
#            end
#          end
#
#          context "and the updated PrimitiveAttribute is not in #projected_set" do
#            attr_reader :photo
#            before do
#              @photo = operand_compound_tuple[photos_set]
#            end
#
#            it "does not trigger #on_tuple_update subscriptions" do
#              projection.on_tuple_update(retainer) do |tuple, attribute, old_value, new_value|
#                raise "Don't taze me bro"
#              end
#              photo[:name] = "Freak show"
#            end
#          end
#        end
      end
#
#      context "when not #retained?" do
#        describe "#tuples" do
#          context "when #projected_set is one of the immediate operands of #operand" do
#            it "returns the unique set of PrimitiveTuples corresponding to #projected_set from the #operand" do
#              projection.tuples.should == operand.tuples.map {|tuple| tuple[projected_set]}.uniq
#            end
#          end
#
#          context "when #projected_set is an operand of an operand of #operand" do
#            before do
#              @projected_set = cameras_set
#              @operand = operand.join(cameras_set).on(photos_set[:camera_id].eq(cameras_set[:id]))
#              @projection = operand.project(projected_set)
#            end
#
#            it "returns the unique set of PrimitiveTuples corresponding to #projected_set from the #operand" do
#              projection.tuples.should == operand.tuples.map {|tuple| tuple[projected_set]}.uniq
#            end
#          end
#        end
#
#        describe "#merge" do
#          it "raises an Exception" do
#            lambda do
#              projection.merge([Photo.new(:id => 100, :user_id => 1, :name => "Photo 100")])
#            end.should raise_error
#          end
#        end
#      end
    end
  end
end
