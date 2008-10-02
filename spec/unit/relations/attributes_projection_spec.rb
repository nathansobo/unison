require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Relations
    describe AttributesProjection do
      attr_reader :operand, :projection, :projected_attributes
      before do
        @projection = AttributesProjection.new(operand, projected_attributes)
        publicize projection, :projected_tuple_for
      end

      def operand
        users_set
      end

      def projected_attributes
        @projected_attributes ||= [User[:name], User[:hobby]]
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
            @projected_attributes ||= [:name, :hobby]
          end

          it "translates the Symbols in the given projected attributes into Attributes" do
            projection.projected_attributes.should == [User[:name], User[:hobby]]
          end
        end
      end

      describe "#attribute" do
        context "when #projected_attributes includes an Attribute with the given name" do
          it "returns the Attribute with the given name" do
            attribute = User[:name]
            projected_attributes.should include(attribute)
            projection.attribute(:name).should == attribute
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
            attribute = User[:name]
            projected_attributes.should include(attribute)
            projection.should have_attribute(:name)
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

        def projected_attributes
          [User[:name], User[:hobby]]
        end

        it "returns an Array of ProjectedTuples corresponding to every Tuple in the #operand" do
          users_set.clear

          user_1 = User.create(:name => "Sloppy Joe", :hobby => "Beef")
          user_2 = User.create(:name => "Rich Lather", :hobby => "Hair")
          user_3 = User.create(:name => "Rich Lather", :hobby => "Hair")
          
          initial_read = projection.initial_read

          initial_read.should include(projection.projected_tuple_for(user_1))
          initial_read.should include(projection.projected_tuple_for(user_2))
          initial_read.should include(projection.projected_tuple_for(user_3))
          initial_read.length.should == 2
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

          context "when #tuples does not contain the ProjectedTuple corresponding to the inserted Tuple" do
            attr_reader :base_tuple, :projected_tuple
            before do
              @base_tuple = User.new(:name => "Brian", :hobby => "Chess")
              @projected_tuple = projection.projected_tuple_for(base_tuple)
              projection.tuples.should_not include(projected_tuple)
            end

            it "inserts the corresponding ProjectedTuple into itself" do
              lambda do
                users_set.insert(base_tuple)
              end.should change{projection.tuples.length}.by(1)

              projection.tuples.should include(projected_tuple)
            end

            it "triggers the on_insert event" do
              inserted = nil
              projection.on_insert(retainer) do |tuple|
                inserted = tuple
              end

              users_set.insert(base_tuple)
              
              inserted.should == projected_tuple
            end
          end

          context "when the ProjectedTuple for the inserted Tuple is already included in #tuples" do
            attr_reader :base_tuple, :projected_tuple

            before do
              @base_tuple = User.new(:name => "Nathan", :hobby => "Yoga")
              @projected_tuple = projection.projected_tuple_for(base_tuple)
              projection.tuples.should include(projected_tuple)
            end

            it "does not insert the new ProjectedTuple into itself" do
              lambda do
                users_set.insert(base_tuple)
              end.should_not change{projection.tuples.length}
            end

            it "does not trigger the on_insert event" do
              projection.on_insert(retainer) do |tuple|
                raise "Don't taze me bro"
              end

              users_set.insert(base_tuple)
            end
          end
        end

        context "when a Tuple is deleted from the #operand" do
          context "when no other Tuple in the operand projects to an equivalent ProjectedTuple" do
            attr_reader :base_tuple, :projected_tuple
            before do
              @base_tuple = operand.find("nathan")
              @projected_tuple = projection.projected_tuple_for(base_tuple)
              operand.tuples.each do |other_base_tuple|
                unless other_base_tuple == base_tuple
                  projection.projected_tuple_for(other_base_tuple).should_not == projected_tuple
                end
              end
            end

            it "removes the corresponding ProjectedTuple from #tuples" do
              projection.tuples.should include(projected_tuple)
              base_tuple.delete
              projection.tuples.should_not include(projected_tuple)
            end

            it "triggers the on_delete event for the deleted ProjectedTuple" do
              deleted = nil
              projection.on_delete(retainer) do |tuple|
                deleted = tuple
              end

              base_tuple.delete
              deleted.should == projected_tuple
            end
          end

          context "when another Tuple in the operand projects to an equivalent ProjectedTuple" do
            attr_reader :base_tuple, :projected_tuple
            before do
              @base_tuple = User.create(:name => "Nathan", :hobby => "Yoga")
              @projected_tuple = projection.projected_tuple_for(base_tuple)

              operand.tuples.select do |other_base_tuple|
                projection.projected_tuple_for(other_base_tuple) == projected_tuple
              end.length.should be > 1
            end

            it "does not remove the corresponding ProjectedTuple from #tuples" do
              projection.should include(projected_tuple)
              base_tuple.delete
              projection.should include(projected_tuple)
            end

            it "does not trigger the on_delete event for the corresponding ProjectedTuple" do
              projection.on_delete(retainer) do |tuple|
                raise "Don't taze me bro"
              end
              base_tuple.delete
            end
          end
        end

#        context "when a Tuple is updated in the #operand" do
#          context "when the update changes the corresponding ProjectedTuple" do
#            context "when another Tuple in the #operand projects to the same ProjectedTuple before the update" do
#              before do
#                User.create(:name => "Nathan", :hobby => "Yoga")
#                base_tuple = User.find("nathan")
#                projected_tuple = projection.projected_tuple_for(base_tuple)
#                operand.tuples.select do |other_base_tuple|
#                  projection.projected_tuple_for(other_base_tuple) == projected_tuple
#                end.size.should be > 1
#              end
#
#              context "when no other Tuple in the #operand projects to the same ProjectedTuple after the update" do
#                base_tuple.name = "Jan"
#                operand.tuples.select do |other_base_tuple|
#                  unless other_base_tuple == base_tuple
#                    projection.projected_tuple_for(other_base_tuple).should_not == projected_tuple
#                  end
#                end
#
#
#              end
#
#
#              context "when another Tuple in the #operand projects to the same ProjectedTuple after the update" do
#
#              end
#            end
#            context "when no other Tuple in the #operand projects to the same ProjectedTuple before the update" do
#              context "when no other Tuple in the #operand projects to the same ProjectedTuple after the update" do
#
#              end
#              context "when another Tuple in the #operand projects to the same ProjectedTuple after the update" do
#
#              end
#            end
#          end
#
#          context "when the update does not change the corresponding ProjectedTuple" do
#
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
