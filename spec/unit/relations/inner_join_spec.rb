require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Relations
    describe InnerJoin do
      attr_reader :join, :predicate
      before do
        @join = InnerJoin.new(left_operand, right_operand, predicate)
      end

      def left_operand
        users_set
      end

      def right_operand
        photos_set
      end

      def predicate
        @predicate ||= Photo[:user_id].eq(User[:id])
      end

      describe "#initialize" do
        it "sets #left_operand, #right_operand, and #predicate" do
          join.left_operand.should == users_set
          join.right_operand.should == photos_set
          predicate.should == Photo[:user_id].eq(User[:id])
        end

        context "when passed in #predicate is a constant value Predicate" do
          it "raises an ArgumentError"
        end
      end

      describe "#fetch_sql" do
        it "returns 'select #left_operand inner join #right_operand on #predicate', with the Attributes aliased to include their table name" do
          join.fetch_sql.should be_like("
            SELECT DISTINCT `users`.`id` AS 'users__id', `users`.`name` AS 'users__name', `users`.`hobby` AS 'users__hobby',
                            `users`.`team_id` AS 'users__team_id', `users`.`developer` AS 'users__developer', 
                            `users`.`show_fans` AS 'users__show_fans', `photos`.`id` AS 'photos__id', `photos`.`user_id` AS 'photos__user_id',
                            `photos`.`camera_id` AS 'photos__camera_id', `photos`.`name` AS 'photos__name'
            FROM `users`
            INNER JOIN `photos` ON `photos`.`user_id` = `users`.`id`
          ")
        end
      end

      describe "#fetch_arel" do
        it "returns an Arel representation of the relation, where the Attributes are aliased to include their table name" do
          arel_join = left_operand.fetch_arel.join(right_operand.fetch_arel).on(predicate.fetch_arel)
          aliased_attributes = arel_join.attributes.map { |a| a.as("#{a.original_relation.name}__#{a.name}") }
          join.fetch_arel.should == arel_join.project(*aliased_attributes)
        end
      end

      describe "#new_tuple" do
        context "when both #left_operand and #right_operand are not #composite?" do
          before do
            left_operand.should_not be_composite
            right_operand.should_not be_composite
          end

          it "instantiates a CompositeTuple with the results of segregating the given attributes hash by qualified table names" do
            qualified_attributes = {
              :users__id => "sharon",
              :users__name => "Sharon Ly",
              :photos__id => "sharon_photo",
              :photos__name => "A photo of Sharon"
            }

            user_attributes = {
              :id => "sharon",
              :name => "Sharon Ly"
            }

            photo_attributes = {
              :id => "sharon_photo",
              :name => "A photo of Sharon"
            }

            join.new_tuple(qualified_attributes).should == CompositeTuple.new(User.new(user_attributes), Photo.new(photo_attributes))
          end
        end
        
        context "when the #left_operand is #composite?" do
          def left_operand
            @left_operand ||= InnerJoin.new(users_set, photos_set, Photo[:user_id].eq(User[:id]))
          end

          def right_operand
            cameras_set
          end

          def predicate
            @predicate ||= Photo[:camera_id].eq(Camera[:id])
          end

          before do
            left_operand.should be_composite
            right_operand.should_not be_composite
          end

          it "instantiates a CompositeTuple with the results of segregating the given attributes hash by qualified table names" do
            qualified_attributes = {
              :users__id => "sharon",
              :users__name => "Sharon Ly",
              :photos__id => "sharon_photo",
              :photos__name => "A photo of Sharon",
              :cameras__id => "minolta",
              :cameras__name => "Minolta"
            }

            user_attributes = {
              :id => "sharon",
              :name => "Sharon Ly"
            }

            photo_attributes = {
              :id => "sharon_photo",
              :name => "A photo of Sharon"
            }

            camera_attributes = {
              :id => "minolta",
              :name => "Minolta"
            }

            join.new_tuple(qualified_attributes).should == CompositeTuple.new(CompositeTuple.new(User.new(user_attributes), Photo.new(photo_attributes)), Camera.new(camera_attributes))
          end
        end

        context "when the #right_operand is #composite?" do
          def left_operand
            users_set
          end

          def right_operand
            @right_operand ||= InnerJoin.new(photos_set, cameras_set, Camera[:id].eq(Photo[:camera_id]))
          end

          def predicate
            @predicate ||= Photo[:user_id].eq(User[:id])
          end

          before do
            left_operand.should_not be_composite
            right_operand.should be_composite
          end

          it "instantiates a CompositeTuple with the results of segregating the given attributes hash by qualified table names" do
            qualified_attributes = {
              :users__id => "sharon",
              :users__name => "Sharon Ly",
              :photos__id => "sharon_photo",
              :photos__name => "A photo of Sharon",
              :cameras__id => "minolta",
              :cameras__name => "Minolta"
            }

            user_attributes = {
              :id => "sharon",
              :name => "Sharon Ly"
            }

            photo_attributes = {
              :id => "sharon_photo",
              :name => "A photo of Sharon"
            }

            camera_attributes = {
              :id => "minolta",
              :name => "Minolta"
            }

            join.new_tuple(qualified_attributes).should == CompositeTuple.new(User.new(user_attributes), CompositeTuple.new(Photo.new(photo_attributes), Camera.new(camera_attributes)))
          end
        end
      end

      describe "#segregate_attributes" do
        before do
          publicize join, :segregate_attributes
        end

        context "when both #left_operand and #right_operand are not #composite?" do
          before do
            left_operand.should_not be_composite
            right_operand.should_not be_composite
          end

          context 'given a hash that is keyed by #{table_name}__#{attribute_name}' do
            context "when all the qualified table names correspond to the left or right operands" do
              it 'returns a hash for each table' do
                qualified_attributes = {
                  :users__id => "sharon",
                  :users__name => "Sharon Ly",
                  :photos__id => "sharon_photo",
                  :photos__name => "A photo of Sharon"
                }

                expected_left = {
                  :id => "sharon",
                  :name => "Sharon Ly"
                }

                expected_right = {
                  :id => "sharon_photo",
                  :name => "A photo of Sharon"
                }

                join.segregate_attributes(qualified_attributes).should == [expected_left, expected_right]
              end
            end

            context "when one of the qualified table names is invalid" do
              it "raises an ArgumentError" do
                qualified_attributes = {
                  :users__id => "sharon",
                  :invalid__id => "sharon_photo"
                }

                lambda do
                  join.segregate_attributes(qualified_attributes)
                end.should raise_error(ArgumentError)
              end
            end
          end
        end

        context "when the #left_operand is #composite?" do
          def left_operand
            @left_operand ||= InnerJoin.new(users_set, photos_set, Photo[:user_id].eq(User[:id]))
          end

          def right_operand
            cameras_set
          end

          def predicate
            @predicate ||= Photo[:camera_id].eq(Camera[:id])
          end

          before do
            left_operand.should be_composite
            right_operand.should_not be_composite
          end

          context 'given a Hash that is keyed by #{table_name}__#{attribute_name}' do
            context "when all the qualified table names correspond to one of the #left_operand's #composed_sets or the #right_operand's #set" do
              it "returns a Hash for the #left_operand that is still qualified with its #composed_sets' names and an unqualified Hash for the #right_operand" do
                qualified_attributes = {
                  :users__id => "sharon",
                  :users__name => "Sharon Ly",
                  :photos__id => "sharon_photo",
                  :photos__name => "A photo of Sharon",
                  :cameras__id => "minolta",
                  :cameras__name => "Minolta"
                }

                expected_left = {
                  :users__id => "sharon",
                  :users__name => "Sharon Ly",
                  :photos__id => "sharon_photo",
                  :photos__name => "A photo of Sharon"
                }

                expected_right = {
                  :id => "minolta",
                  :name => "Minolta"
                }

                join.segregate_attributes(qualified_attributes).should == [expected_left, expected_right]
              end
            end

            context "when one of the qualified table names is invalid" do
              it "raises an ArgumentError" do
                qualified_attributes = {
                  :users__id => "sharon",
                  :invalid__id => "sharon_photo"
                }

                lambda do
                  join.segregate_attributes(qualified_attributes)
                end.should raise_error(ArgumentError)
              end
            end
          end
        end

        context "when the #right_operand is #composite?" do
          def left_operand
            users_set
          end

          def right_operand
            @right_operand ||= InnerJoin.new(photos_set, cameras_set, Camera[:id].eq(Photo[:camera_id]))
          end

          def predicate
            @predicate ||= Photo[:user_id].eq(User[:id])
          end

          before do
            left_operand.should_not be_composite
            right_operand.should be_composite
          end

          context 'given a Hash that is keyed by #{table_name}__#{attribute_name}' do
            context "when all the qualified table names correspond to the #left_operand's #set or one of the #right_operand's #composed_sets" do
              it "returns an unqualified Hash for the #left_operand and a Hash for the #right_operand that is still qualified with its #composed_sets' names" do
                qualified_attributes = {
                  :users__id => "sharon",
                  :users__name => "Sharon Ly",
                  :photos__id => "sharon_photo",
                  :photos__name => "A photo of Sharon",
                  :cameras__id => "minolta",
                  :cameras__name => "Minolta"
                }

                expected_left = {
                  :id => "sharon",
                  :name => "Sharon Ly",
                }

                expected_right = {
                  :photos__id => "sharon_photo",
                  :photos__name => "A photo of Sharon",
                  :cameras__id => "minolta",
                  :cameras__name => "Minolta"
                }

                join.segregate_attributes(qualified_attributes).should == [expected_left, expected_right]
              end
            end

            context "when one of the qualified table names is invalid" do
              it "raises an ArgumentError" do
                qualified_attributes = {
                  :users__id => "sharon",
                  :invalid__id => "sharon_photo"
                }

                lambda do
                  join.segregate_attributes(qualified_attributes)
                end.should raise_error(ArgumentError)
              end
            end
          end
        end
      end

      describe "#push" do
        before do
          origin.connection[:users].delete
          origin.connection[:photos].delete
        end

        context "when #composed_sets.size == 2" do
          it "pushes a SetProjection of both composed_sets represented in the InnerJoin to the given Repository" do
            users_projection = join.project(users_set)
            photos_projection = join.project(photos_set)

            mock.proxy(origin).push(users_projection)
            mock.proxy(origin).push(photos_projection)

            join.push

            users_projection.pull.should == users_projection.tuples
            photos_projection.pull.should == photos_projection.tuples
          end
        end

        context "when #composed_sets.size == 3" do
          before do
            @join = join.join(cameras_set).on(Photo[:camera_id].eq(Camera[:id]))
            join.composed_sets.size.should == 3
          end

          it "pushes a SetProjection of the three composed_sets represented in the InnerJoin to the given Repository" do
            users_projection = join.project(users_set)
            photos_projection = join.project(photos_set)
            cameras_projection = join.project(cameras_set)

            mock.proxy(origin).push(users_projection)
            mock.proxy(origin).push(photos_projection)
            mock.proxy(origin).push(cameras_projection)

            join.push

            users_projection.pull.should == users_projection.tuples
            photos_projection.pull.should == photos_projection.tuples
            cameras_projection.pull.should == cameras_projection.tuples
          end
        end
      end

      describe "#composite?" do
        it "returns true" do
          join.should be_composite
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
            join.composed_sets.should == left_operand.composed_sets + right_operand.composed_sets
          end
        end

        context "when one of operands contains CompositeTuples" do
          before do
            @join = join.join(cameras_set).on(Photo[:camera_id].eq(Camera[:id]))
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
            left_operand.should have_attribute(name)
            right_operand.should have_attribute(name)
          end

          it "returns the value of #left_operand.attribute for the name" do
            join.attribute(name).should == left_operand.attribute(name)
          end
        end

        context "when an Attribute with the given #name is defined only on #right_operand" do
          before do
            @name = :user_id
            left_operand.should_not have_attribute(name)
            right_operand.should have_attribute(name)
          end

          it "returns the value of #left_operand.attribute for the name" do
            join.attribute(name).should == right_operand.attribute(name)
          end
        end

        context "when no operand has an Attribute with the given name" do
          before do
            @name = :hussein
            left_operand.should_not have_attribute(name)
            right_operand.should_not have_attribute(name)
          end

          it "raises an ArgumentError" do
            lambda do
              join.attribute(name)
            end.should raise_error(ArgumentError)
          end
        end
      end

      describe "#merge" do
        it "merges all the #left components of the given CompositeTuples into the #left_operand" do
          user = User.new(:id => "sharon", :name => "Sharon Ly")
          photo_1 = Photo.new(:id => "sharon_photo_1", :user_id => "sharon")
          photo_2 = Photo.new(:id => "sharon_photo_2", :user_id => "sharon")

          composite_tuples = [
            CompositeTuple.new(user, photo_1),
            CompositeTuple.new(user, photo_2)
          ]

          left_operand.find("sharon").should be_nil
          right_operand.find("sharon_photo_1").should be_nil
          right_operand.find("sharon_photo_2").should be_nil

          join.merge(composite_tuples)

          left_operand.find("sharon").should == user
          right_operand.find("sharon_photo_1").should == photo_1
          right_operand.find("sharon_photo_2").should == photo_2

        end
      end

      describe "attribute" do
        context "when #left_operand.has_attribute? is true" do
          it "delegates to #left_operand" do
            left_operand_attribute = left_operand.attribute(:id)
            left_operand_attribute.should_not be_nil

            mock.proxy(left_operand).attribute(:id)
            join.attribute(:id).should == left_operand_attribute
          end
        end

        context "when #left_operand.has_attribute? is false" do
          it "delegates to #right_operand" do
            left_operand.should_not have_attribute(:user_id)
            right_operand.should have_attribute(:user_id)
            right_operand_attribute = right_operand.attribute(:user_id)

            dont_allow(left_operand).attribute(:user_id)
            mock.proxy(right_operand).attribute(:user_id)
            join.attribute(:user_id).should == right_operand_attribute
          end
        end
      end

      describe "#has_attribute?" do
        context "when #left_operand.has_attribute? is true" do
          it "delegates to #left_operand" do
            left_operand.has_attribute?(:id).should be_true

            mock.proxy(left_operand).has_attribute?(:id)
            join.has_attribute?(:id).should be_true
          end
        end

        context "when #left_operand.has_attribute? is false" do
          it "delegates to #left_operand and #right_operand" do
            left_operand.has_attribute?(:user_id).should be_false
            right_operand.has_attribute?(:user_id).should be_true

            mock.proxy(left_operand).has_attribute?(:user_id)
            mock.proxy(right_operand).has_attribute?(:user_id)
            join.has_attribute?(:user_id).should be_true
          end
        end
      end

      context "when #retained?" do
        attr_reader :retainer
        before do
          @retainer = Object.new
          join.retain_with(retainer)
        end

        after do
          join.release_from(retainer)
        end

        context "when a Tuple is inserted into #left_operand" do
          context "when the inserted Tuple creates a CompositeTuple that matches the #predicate" do
            attr_reader :photo, :user, :tuple_class, :expected_tuple
            before do
              @tuple_class = CompositeTuple
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
              join.on_insert(retainer) do |tuple|
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

          context "when the inserted Tuple creates a CompositeTuple that does not match the #predicate" do
            attr_reader :photo, :user, :tuple_class, :expected_tuple
            before do
              @tuple_class = CompositeTuple
              @photo = Photo.create(:id => 100, :user_id => 999, :name => "Photo 100")
              @user = User.new(:id => 100, :name => "Brian")
              @expected_tuple = tuple_class.new(user, photo)
              predicate.eval(expected_tuple).should be_false
            end

            it "does not add the CompositeTuple to the result of #tuples" do
              join.should_not include(expected_tuple)
              users_set.insert(user)
              join.should_not include(expected_tuple)
            end

            it "does not trigger the on_insert event" do
              join.on_insert(retainer) do |tuple|
                raise "Don't taze me bro"
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

        context "when a Tuple is inserted into #right_operand" do
          context "when the inserted Tuple creates a CompositeTuple that matches the #predicate" do
            attr_reader :photo, :user, :tuple_class, :expected_tuple
            before do
              @tuple_class = CompositeTuple
              @photo = Photo.new(:id => 100, :user_id => 100, :name => "Photo 100")
              @user = User.create(:id => 100, :name => "Brian")
              @expected_tuple = tuple_class.new(user, photo)
              predicate.eval(expected_tuple).should be_true
            end

            it "adds the CompositeTuple to the result of #tuples" do
              join.should_not include(expected_tuple)
              photos_set.insert(photo)
              join.should include(expected_tuple)
            end

            it "trigger the on_insert event" do
              inserted = nil
              join.on_insert(retainer) do |tuple|
                inserted = tuple
              end
              photos_set.insert(photo)

              predicate.eval(inserted).should be_true
              inserted[photos_set].should == photo
              inserted[users_set].should == user
            end
            
            it "retains the CompositeTuple" do
              join.where(Photo[:id].eq(photo[:id])).should be_empty
              photos_set.insert(photo)
              join.where(Photo[:id].eq(photo[:id])).first.should be_retained_by(join)
            end
          end

          context "when the inserted Tuple creates a CompositeTuple that does not match the #predicate" do
            attr_reader :photo, :user, :tuple_class, :expected_tuple
            before do
              @tuple_class = CompositeTuple
              @photo = Photo.new(:id => 100, :user_id => 999, :name => "Photo 100")
              @user = User.create(:id => 100, :name => "Brian")
              @expected_tuple = tuple_class.new(user, photo)
              predicate.eval(expected_tuple).should be_false
            end

            it "does not add the CompositeTuple to the result of #tuples" do
              join.should_not include(expected_tuple)
              photos_set.insert(photo)
              join.should_not include(expected_tuple)
            end

            it "does not trigger the on_insert event" do
              join.on_insert(retainer) do |tuple|
                raise "Don't taze me bro"
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

        context "when a Tuple is deleted from #left_operand" do
          attr_reader :user, :tuple_class
          context "when the Tuple is a component of some CompositeTuple in #tuples" do
            attr_reader :photo, :composite_tuple
            before do
              @tuple_class = CompositeTuple
              @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")
              @user = User.create(:id => 100, :name => "Brian")
              @composite_tuple = join.detect {|tuple| tuple[users_set] == user && tuple[photos_set] == photo}
              predicate.eval(composite_tuple).should be_true
              join.should include(composite_tuple)
            end

            it "deletes the CompositeTuple from the result of #tuples" do
              users_set.delete(user)
              join.should_not include(composite_tuple)
            end

            it "triggers the on_delete event" do
              deleted = nil
              join.on_delete(retainer) do |deleted_tuple|
                deleted = deleted_tuple
              end

              users_set.delete(user)
              deleted.should == composite_tuple
            end

            it "#releases the Tuple" do
              composite_tuple = join.find(user.id)
              composite_tuple.should be_retained_by(join)
              users_set.delete(user)
              composite_tuple.should_not be_retained_by(join)
            end
          end

          context "when the Tuple is not a component of any CompositeTuple in #tuples" do
            before do
              @tuple_class = CompositeTuple
              @user = User.create(:id => 100, :name => "Brian")
              join.any? do |composite_tuple|
                composite_tuple[users_set] == user
              end.should be_false
            end

            it "does not delete a CompositeTuple from the result of #tuples" do
              lambda do
                users_set.delete(user)
              end.should_not change{join.length}
            end

            it "does not trigger the on_delete event" do
              join.on_delete(retainer) do |deleted_tuple|
                raise "Don't taze me bro"
              end
              users_set.delete(user)
            end
          end
        end

        context "when a Tuple is deleted from #right_operand" do
          attr_reader :photo, :tuple_class
          context "when the Tuple is a component of some CompositeTuple in #tuples" do
            attr_reader :user, :composite_tuple
            before do
              @tuple_class = CompositeTuple
              @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")
              @user = User.create(:id => 100, :name => "Brian")
              @composite_tuple = join.detect {|tuple| tuple[users_set] == user && tuple[photos_set] == photo}
              predicate.eval(composite_tuple).should be_true
              join.should include(composite_tuple)
            end

            it "deletes the CompositeTuple from the result of #tuples" do
              photos_set.delete(photo)
              join.should_not include(composite_tuple)
            end

            it "triggers the on_delete event" do
              deleted = nil
              join.on_delete(retainer) do |deleted_tuple|
                deleted = deleted_tuple
              end

              photos_set.delete(photo)
              deleted.should == composite_tuple
            end

            it "#releases the Tuple" do
              composite_tuple = join.where(Photo[:id].eq(photo[:id])).first
              composite_tuple.should be_retained_by(join)
              photos_set.delete(photo)
              composite_tuple.should_not be_retained_by(join)
            end
          end

          context "when the Tuple is not a component of any CompositeTuple in #tuples" do
            before do
              @tuple_class = CompositeTuple
              @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")
              join.any? do |composite_tuple|
                composite_tuple[photos_set] == photo
              end.should be_false
            end

            it "does not delete a CompositeTuple from the result of #tuples" do
              lambda do
                photos_set.delete(photo)
              end.should_not change{join.length}
            end

            it "does not trigger the on_delete event" do
              join.on_delete(retainer) do |deleted_tuple|
                raise "Don't taze me bro"
              end
              photos_set.delete(photo)
            end
          end
        end

        context "when a Tuple in #left_operand is updated" do
          context "when the Tuple is not a component of any CompositeTuple in #tuples" do
            attr_reader :user, :photo, :expected_composite_tuple
            before do
              @user = users_set.tuples.first
              @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")
              @expected_composite_tuple = CompositeTuple.new(user, photo)
            end

            context "when the update causes a CompositeTuple to match the #predicate" do
              it "adds that CompositeTuple to the result of #tuples" do
                join.should_not include(expected_composite_tuple)
                user[:id] = photo[:user_id]
                join.should include(expected_composite_tuple)
              end

              it "triggers the on_insert event" do
                inserted = nil
                join.on_insert(retainer) do |tuple|
                  inserted = tuple
                end
                user[:id] = photo[:user_id]

                predicate.eval(inserted).should be_true
                inserted[photos_set].should == photo
                inserted[users_set].should == user
              end

              it "retains the CompositeTuple" do
                join.where(Photo[:id].eq(photo[:id])).should be_empty
                user[:id] = photo[:user_id]
                join.where(Photo[:id].eq(photo[:id])).tuples.first.should be_retained_by(join)
              end
            end

            context "when the update does not cause the Tuple to match the #predicate" do
              it "does not add the Tuple into the result of #tuples" do
                join.should_not include(expected_composite_tuple)
                user[:id] = photo[:user_id] + "junk"
                join.should_not include(expected_composite_tuple)
              end

              it "does not trigger the on_insert event" do
                join.on_insert(retainer) do |tuple|
                  raise "Do not call me"
                end
                user[:id] = photo[:user_id] + "junk"
              end
            end
          end

          context "when the Tuple is a component of some CompositeTuple in #tuples" do
            attr_reader :composite_tuples, :user
            before do
              @user = User.find("nathan")
              @composite_tuples = join.select do |composite_tuple|
                composite_tuple[users_set] == user
              end
              composite_tuples.size.should be > 1
              composite_tuples.each do |composite_tuple|
                join.should include(composite_tuple)
              end
            end

            context "when the update causes the CompositeTuple to not match the #predicate" do
              it "removes the Tuple from the result of #tuples" do
                user[:id] = 100
                composite_tuples.each do |composite_tuple|
                  join.should_not include(composite_tuple)
                end
              end

              it "triggers the on_delete event" do
                deleted = []
                join.on_delete(retainer) do |tuple|
                  deleted.push tuple
                end
                user[:id] = 100
                deleted.size.should == composite_tuples.size
                composite_tuples.each do |composite_tuple|
                  deleted.should include(composite_tuple)
                end
              end

              it "releases the CompositeTuple" do
                composite_tuple = join.find(user.id)
                composite_tuple.should be_retained_by(join)
                user[:id] = 100
                composite_tuple.should_not be_retained_by(join)
              end
            end

            context "when the CompositeTuple continues to match the #predicate after the update" do
              it "does not remove that CompositeTuple from the results of #tuples" do
                user[:name] = "Joe"
                composite_tuples.each do |composite_tuple|
                  join.should include(composite_tuple)
                end
              end

              it "triggers the on_tuple_update event for the CompositeTuple" do
                updated = []
                join.on_tuple_update(retainer) do |tuple, attribute, old_value, new_value|
                  updated.push [tuple, attribute, old_value, new_value]
                end
                old_name = user[:name]
                user[:name] = "Joe"
                updated.size.should == composite_tuples.size
                composite_tuples.each do |composite_tuple|
                  updated.should include([composite_tuple, User[:name], old_name, "Joe"])
                end
              end

              it "does not trigger the on_insert or on_delete event" do
                join.on_insert(retainer) do |tuple|
                  raise "Don't taze me bro"
                end
                join.on_delete(retainer) do |tuple|
                  raise "Don't taze me bro"
                end
                user[:name] = "Joe"
              end
            end
          end
        end

        context "when a Tuple in #right_operand is updated" do
          context "when the Tuple is not a component of any CompositeTuple in #tuples" do
            attr_reader :user, :photo, :expected_composite_tuple
            before do
              @user = users_set.tuples.first
              @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")
              @expected_composite_tuple = CompositeTuple.new(user, photo)
            end

            context "when the update causes a CompositeTuple to match the #predicate" do
              it "adds that CompositeTuple to the result of #tuples" do
                join.should_not include(expected_composite_tuple)
                photo[:user_id] = user[:id]
                join.should include(expected_composite_tuple)
              end

              it "triggers the on_insert event" do
                inserted = nil
                join.on_insert(retainer) do |tuple|
                  inserted = tuple
                end
                photo[:user_id] = user[:id]

                predicate.eval(inserted).should be_true
                inserted[photos_set].should == photo
                inserted[users_set].should == user
              end

              it "retains the CompositeTuple" do
                join.where(Photo[:id].eq(photo[:id])).should be_empty
                photo[:user_id] = user[:id]
                join.where(Photo[:id].eq(photo[:id])).first.should be_retained_by(join)
              end
            end

            context "when the update does not cause the Tuple to match the #predicate" do
              it "does not add the Tuple into the result of #tuples" do
                join.should_not include(expected_composite_tuple)
                photo[:user_id] = 1000
                join.should_not include(expected_composite_tuple)
              end

              it "does not trigger the on_insert event" do
                join.on_insert(retainer) do |tuple|
                  raise "Do not call me"
                end
                photo[:user_id] = 1000
              end
            end
          end

          context "when the Tuple is a component of some CompositeTuple in #tuples" do
            attr_reader :composite_tuple, :photo
            before do
              @photo = photos_set.tuples.first
              @composite_tuple = join.tuples.find do |composite_tuple|
                composite_tuple[photos_set] == photo
              end
              join.should include(composite_tuple)
            end

            context "when the update causes the CompositeTuple to not match the #predicate" do
              it "removes the Tuple from the result of #tuples" do
                photo[:user_id] = 100
                join.should_not include(composite_tuple)
              end

              it "triggers the on_delete event" do
                deleted = []
                join.on_delete(retainer) do |tuple|
                  deleted.push tuple
                end
                photo[:user_id] = 100
                deleted.should == [composite_tuple]
              end

              it "releases the CompositeTuple" do
                composite_tuple = join.where(Photo[:id].eq(photo.id)).first
                composite_tuple.should be_retained_by(join)

                photo[:user_id] = 100

                composite_tuple.should_not be_retained_by(join)
              end
            end

            context "when the CompositeTuple continues to match the #predicate after the update" do
              it "does not remove that CompositeTuple from the results of #tuples" do
                photo[:name] = "A great naked show"
                join.should include(composite_tuple)
              end

              it "triggers the on_tuple_update event for the CompositeTuple" do
                updated = []
                join.on_tuple_update(retainer) do |tuple, attribute, old_value, new_value|
                  updated.push [tuple, attribute, old_value, new_value]
                end
                old_value = photo[:name]
                new_value = "A great naked show part 2"
                photo[:name] = new_value
                updated.should == [[composite_tuple, Photo[:name], old_value, new_value]]
              end

              it "does not trigger the on_insert or on_delete event" do
                join.on_insert(retainer) do |tuple|
                  raise "Don't taze me bro"
                end
                join.on_delete(retainer) do |tuple|
                  raise "Don't taze me bro"
                end
                photo[:name] = "A great naked show part 3"
              end
            end
          end
        end

        describe "#find_composite_tuple" do
          attr_reader :photo, :user
          before do
            publicize join, :find_composite_tuple
          end
          context "when #tuples contains a CompositeTuple that contains both of the arguments" do
            before do
              @user = User.create(:id => 100, :name => "Brian")
              @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")

              join.tuples.any? do |composite_tuple|
                composite_tuple[users_set] == user &&
                  composite_tuple[photos_set] == photo
              end.should be_true
            end

            it "returns the CompositeTuple" do
              composite_tuple = join.find_composite_tuple(user, photo)
              composite_tuple[users_set].should == user
              composite_tuple[photos_set].should == photo
            end
          end

          context "when #tuples only contains a CompositeTuple that contains the first argument" do
            before do
              @user = User.find("nathan")
              @photo = Photo.create(:id => 100, :user_id => 100, :name => "Photo 100")

              join.tuples.any? do |composite_tuple|
                composite_tuple[users_set] == user &&
                  composite_tuple[photos_set] == photo
              end.should be_false

              join.tuples.any? do |composite_tuple|
                composite_tuple[users_set] == user
              end.should be_true
            end


            it "returns nil" do
              join.find_composite_tuple(user, photo).should be_nil
            end
          end

          context "when #tuples only contains a CompositeTuple that contains the second argument" do
            before do
              @user = User.create(:id => "brian", :name => "Brian")
              @photo = Photo.find("nathan_photo_1")

              join.tuples.any? do |composite_tuple|
                composite_tuple[users_set] == user &&
                  composite_tuple[photos_set] == photo
              end.should be_false

              join.tuples.any? do |composite_tuple|
                composite_tuple[photos_set] == photo
              end.should be_true
            end

            it "returns nil" do
              join.find_composite_tuple(user, photo).should be_nil
            end
          end
        end
      end

      context "when not #retained?" do
        describe "#after_first_retain" do
          attr_reader :retainer
          before do
            @retainer = Object.new
          end

          after do
            join.release_from(retainer)
          end

          it "retains the Tuples inserted by #initial_read" do
            join.retain_with(retainer)
            join.should_not be_empty
            join.each do |tuple|
              tuple.should be_retained_by(join)
            end
          end
        end

        describe "#tuples" do
          it "returns all tuples in its operands for which its predicate returns true" do
            tuples = join
            tuples.size.should == 3

            nathan = User.find("nathan")
            corey = User.find("corey")
            nathan_photo_1 = Photo.find("nathan_photo_1")
            nathan_photo_2 = Photo.find("nathan_photo_2")
            corey_photo_1 = Photo.find("corey_photo_1")

            tuples[0][User[:id]].should == nathan.id
            tuples[0][User[:name]].should == nathan.name
            tuples[0][Photo[:id]].should == nathan_photo_1.id
            tuples[0][Photo[:user_id]].should == nathan_photo_1.user_id
            tuples[0][Photo[:name]].should == nathan_photo_1.name

            tuples[1][User[:id]].should == nathan.id
            tuples[1][User[:name]].should == nathan.name
            tuples[1][Photo[:id]].should == nathan_photo_2.id
            tuples[1][Photo[:user_id]].should == nathan_photo_2.user_id
            tuples[1][Photo[:name]].should == nathan_photo_2.name

            tuples[2][User[:id]].should == corey.id
            tuples[2][User[:name]].should == corey.name
            tuples[2][Photo[:id]].should == corey_photo_1.id
            tuples[2][Photo[:user_id]].should == corey_photo_1.user_id
            tuples[2][Photo[:name]].should == corey_photo_1.name
          end

          context "when #left_operand is an empty singleton Relation" do
            def left_operand
              users_set.where(User[:id].eq(-1)).singleton
            end
            
            it "returns an empty Array" do
              join.tuples.should == []
            end
          end

          context "when #right_operand is an empty singleton Relation" do
            def right_operand
              photos_set.where(Photo[:id].eq(-1)).singleton
            end

            it "returns an empty Array" do
              join.tuples.should == []
            end
          end
        end
      end

      context "with complex operands" do
        def left_operand
          @left_operand ||= InnerJoin.new(users_set, photos_set, Photo[:user_id].eq(User[:id]))
        end

        def right_operand
          cameras_set
        end

        def predicate
          @predicate ||= Photo[:camera_id].eq(Camera[:id])
        end

        context "when #retained?" do
          attr_reader :retainer
          before do
            @retainer = Object.new
            join.retain_with(retainer)
          end

          after do
            join.release_from(retainer)
          end

          context "when a Tuple is inserted into #left_operand" do
            context "when the inserted Tuple creates a CompositeTuple that matches the #predicate" do
              attr_reader :photo, :expected_tuple
              before do
                user = User.find("nathan")
                camera = Camera.find("minolta")
                @photo = Photo.new(:id => "nathan_photo_3", :user_id => user[:id], :camera_id => camera[:id])
                @expected_tuple = CompositeTuple.new(CompositeTuple.new(user, photo), camera)
                predicate.eval(expected_tuple).should be_true
              end

              it "adds the CompositeTuple to the result of #tuples" do
                join.should_not include(expected_tuple)
                photos_set.insert(photo)
                join.should include(expected_tuple)
              end

              it "triggers the on_insert event" do
                inserted = nil
                join.on_insert(retainer) do |tuple|
                  inserted = tuple
                end
                photos_set.insert(photo)

                inserted.should == expected_tuple
              end

              it "retains the CompositeTuple" do
                join.find(Photo[:id].eq("nathan_photo_3")).should be_nil
                photos_set.insert(photo)
                join.find(Photo[:id].eq("nathan_photo_3")).should be_retained_by(join)
              end
            end

            context "when the inserted Tuple creates a CompositeTuple that does not match the #predicate" do
              attr_reader :photo, :user, :tuple_class, :expected_tuple
              before do
                user = User.find("nathan")
                Camera.find("polaroid").should be_nil
                @photo = Photo.new(:id => "nathan_photo_3", :user_id => user[:id], :camera_id => "polaroid")
              end

              it "does not add the CompositeTuple to the result of #tuples" do
                lambda do
                  photos_set.insert(photo)
                end.should_not change {join.tuples.length}
              end

              it "does not trigger the on_insert event" do
                join.on_insert(retainer) do |tuple|
                  raise "Don't taze me bro"
                end
                photos_set.insert(photo)
              end
            end
          end

          context "when a Tuple is inserted into #right_operand" do
            context "when the inserted Tuple creates a CompositeTuple that matches the #predicate" do
              attr_reader :camera, :expected_tuple
              before do
                user = User.find("nathan")
                photo = Photo.create(:id => "nathan_photo_3", :user_id => "nathan", :camera_id => "nikon")
                @camera = Camera.new(:id => "nikon")

                @expected_tuple = CompositeTuple.new(CompositeTuple.new(user, photo), camera)
                predicate.eval(expected_tuple).should be_true
              end

              it "adds the CompositeTuple to the result of #tuples" do
                join.should_not include(expected_tuple)
                cameras_set.insert(camera)
                join.should include(expected_tuple)
              end

              it "trigger the on_insert event" do
                inserted = nil
                join.on_insert(retainer) do |tuple|
                  inserted = tuple
                end
                cameras_set.insert(camera)
                
                inserted.should == expected_tuple
              end

              it "retains the CompositeTuple" do
                join.find(Camera[:id].eq(camera.id)).should be_nil
                cameras_set.insert(camera)
                join.find(Camera[:id].eq(camera.id)).should be_retained_by(join)
              end
            end

            context "when the inserted Tuple creates a CompositeTuple that does not match the #predicate" do
              attr_reader :camera
              before do
                @camera = Camera.new(:id => "nikon")
                photos_set.find(Photo[:camera_id].eq(camera[:id])).should be_nil
              end

              it "does not add the CompositeTuple to the result of #tuples" do
                lambda do
                  cameras_set.insert(camera)
                end.should_not change {join.tuples.length}
              end

              it "does not trigger the on_insert event" do
                join.on_insert(retainer) do |tuple|
                  raise "Don't taze me bro"
                end
                cameras_set.insert(camera)
              end
            end
          end

          context "when a Tuple is deleted from #left_operand" do
            attr_reader :user, :tuple_class
            context "when the Tuple is a component of some CompositeTuple in #tuples" do
              attr_reader :photo, :composite_tuple
              before do
                @photo = Photo.find("nathan_photo_1")
                @composite_tuple = join.find(Photo[:id].eq(photo[:id]))
                composite_tuple.should_not be_nil
              end

              it "deletes the CompositeTuple from the result of #tuples" do
                join.should include(composite_tuple)
                photo.delete
                join.should_not include(composite_tuple)
              end

              it "triggers the on_delete event" do
                deleted = nil
                join.on_delete(retainer) do |deleted_tuple|
                  deleted = deleted_tuple
                end

                photo.delete
                deleted.should == composite_tuple
              end

              it "#releases the Tuple" do
                composite_tuple.should be_retained_by(join)
                photo.delete
                composite_tuple.should_not be_retained_by(join)
              end
            end

            context "when the Tuple is not a component of any CompositeTuple in #tuples" do
              attr_reader :photo
              before do
                @photo = Photo.create(:id => "orphan", :user_id => "farbooooood")
                join.find(Photo[:id].eq(photo[:id])).should be_nil
              end

              it "does not delete a CompositeTuple from the result of #tuples" do
                lambda do
                  photo.delete
                end.should_not change { join.tuples.length }
              end

              it "does not trigger the on_delete event" do
                join.on_delete(retainer) do |deleted_tuple|
                  raise "Don't taze me bro"
                end
                photo.delete
              end
            end
          end

          context "when a Tuple is deleted from #right_operand" do
            context "when the Tuple is a component of some CompositeTuple in #tuples" do
              attr_reader :camera, :composite_tuple
              before do
                @camera = Camera.find("minolta")
                @composite_tuple = join.find(Camera[:id].eq(camera[:id]))
                composite_tuple.should_not be_nil
              end

              it "deletes the CompositeTuple from the result of #tuples" do
                join.should include(composite_tuple)
                camera.delete
                join.should_not include(composite_tuple)
              end

              it "triggers the on_delete event" do
                deleted = []
                join.on_delete(retainer) do |deleted_tuple|
                  deleted.push(deleted_tuple)
                end

                camera.delete
                deleted.should include(composite_tuple)
              end

              it "#releases the Tuple" do
                composite_tuple.should be_retained_by(join)
                camera.delete
                composite_tuple.should_not be_retained_by(join)
              end
            end

            context "when the Tuple is not a component of any CompositeTuple in #tuples" do
              attr_reader :camera
              before do
                @camera = Camera.create(:id => "nikon")
                join.find(Camera[:id].eq(camera[:id])).should be_nil
              end

              it "does not delete a CompositeTuple from the result of #tuples" do
                lambda do
                  camera.delete
                end.should_not change { join.tuples.length }
              end

              it "does not trigger the on_delete event" do
                join.on_delete(retainer) do |deleted_tuple|
                  raise "Don't taze me bro"
                end
                camera.delete
              end
            end
          end

          context "when a Tuple in #left_operand is updated" do
            context "when the Tuple is not a component of any CompositeTuple in #tuples" do
              attr_reader :user, :photo, :camera, :expected_composite_tuple
              before do
                @user = User.find("nathan")
                @photo = Photo.create(:id => "nathan_photo_3", :user_id => "nathan", :camera_id => "no_camera_right_now")
                @camera = Camera.create(:id => "el_camera")
                @expected_composite_tuple = CompositeTuple.new(CompositeTuple.new(user, photo), camera)
                join.find(Photo[:id].eq(photo[:id])).should be_nil
              end

              context "when the update causes a CompositeTuple to match the #predicate" do
                it "adds that CompositeTuple to the result of #tuples" do
                  join.should_not include(expected_composite_tuple)
                  photo[:camera_id] = camera[:id]
                  join.should include(expected_composite_tuple)
                end

                it "triggers the on_insert event" do
                  inserted = nil
                  join.on_insert(retainer) do |tuple|
                    inserted = tuple
                  end
                  photo[:camera_id] = camera[:id]
                  inserted.should == expected_composite_tuple
                end

                it "retains the CompositeTuple" do
                  join.find(Camera[:id].eq(camera[:id])).should be_nil
                  photo[:camera_id] = camera[:id]
                  join.find(Camera[:id].eq(camera[:id])).should be_retained_by(join)
                end
              end

              context "when the update does not cause the Tuple to match the #predicate" do
                it "does not add the Tuple into the result of #tuples" do
                  lambda do
                    photo[:camera_id] = "das_kamera"
                  end.should_not change { join.tuples.length }
                end

                it "does not trigger the on_insert event" do
                  join.on_insert(retainer) do |tuple|
                    raise "Don't taze me bro"
                  end
                  photo[:camera_id] = "das_kamera"
                end
              end
            end

            context "when the Tuple is a component of some CompositeTuple in #tuples" do
              attr_reader :composite_tuple, :photo
              before do
                user = User.find("nathan")
                @photo = Photo.find("nathan_photo_1")
                camera = Camera.find(photo[:camera_id])
                @composite_tuple = join.find(Photo[:id].eq(photo[:id]))
              end

              context "when the update causes the CompositeTuple to not match the #predicate" do
                it "removes the Tuple from the result of #tuples" do
                  join.tuples.should include(composite_tuple)
                  photo[:camera_id] = "das_kamera"
                  join.tuples.should_not include(composite_tuple)
                end

                it "triggers the on_delete event" do
                  deleted = nil
                  join.on_delete(retainer) do |tuple|
                    deleted = tuple
                  end
                  photo[:camera_id] = "das_kamera"
                  deleted.should == composite_tuple
                end

                it "releases the CompositeTuple" do
                  composite_tuple.should be_retained_by(join)
                  photo[:camera_id] = "das_kamera"
                  composite_tuple.should_not be_retained_by(join)
                end
              end

              context "when the CompositeTuple continues to match the #predicate after the update" do
                it "does not remove that CompositeTuple from the results of #tuples" do
                  join.tuples.should include(composite_tuple)
                  photo[:name] = "Sexy one"
                  join.tuples.should include(composite_tuple)
                end

                it "triggers the on_tuple_update event for the CompositeTuple" do
                  updated = []
                  join.on_tuple_update(retainer) do |tuple, attribute, old_value, new_value|
                    updated.push [tuple, attribute, old_value, new_value]
                  end
                  old_name = photo[:name]
                  photo[:name] = "Moo"
                  updated.should == [[composite_tuple, Photo[:name], old_name, "Moo"]]
                end

                it "does not trigger the on_insert or on_delete event" do
                  join.on_insert(retainer) do |tuple|
                    raise "Don't taze me bro"
                  end
                  join.on_delete(retainer) do |tuple|
                    raise "Don't taze me bro"
                  end
                  photo[:name] = "Barfing"
                end
              end
            end
          end

          context "when a Tuple in #right_operand is updated" do
            context "when the Tuple is not a component of any CompositeTuple in #tuples" do
              attr_reader :photo, :camera, :expected_composite_tuple
              before do
                user = User.find("nathan")
                @photo = Photo.create(:id => "nathan_photo_3", :user_id => "nathan", :camera_id => "das_kamera")
                @camera = Camera.find("canon")
                @expected_composite_tuple = CompositeTuple.new(CompositeTuple.new(user, photo), camera)
                Camera.find(photo[:camera_id]).should be_nil
              end

              context "when the update causes a CompositeTuple to match the #predicate" do
                it "adds that CompositeTuple to the result of #tuples" do
                  join.should_not include(expected_composite_tuple)
                  camera[:id] = photo[:camera_id]
                  join.should include(expected_composite_tuple)
                end

                it "triggers the on_insert event" do
                  inserted = nil
                  join.on_insert(retainer) do |tuple|
                    inserted = tuple
                  end
                  camera[:id] = photo[:camera_id]
                  inserted.should == expected_composite_tuple
                end

                it "retains the CompositeTuple" do
                  join.find(Photo[:id].eq(photo[:id])).should be_nil
                  camera[:id] = photo[:camera_id]
                  join.find(Photo[:id].eq(photo[:id])).should be_retained_by(join)
                end
              end

              context "when the update does not cause the Tuple to match the #predicate" do
                it "does not add the Tuple into the result of #tuples" do
                  lambda do
                    camera[:name] = "Some craaaazzy camera"
                  end.should_not change { join.tuples.length }
                end

                it "does not trigger the on_insert event" do
                  join.on_insert(retainer) do |tuple|
                    raise "Don't taze me bro"
                  end
                  camera[:name] = "Some craaaazzy camera"
                end
              end
            end

            context "when the Tuple is a component of some CompositeTuple in #tuples" do
              attr_reader :camera, :composite_tuple
              before do
                user = User.find("nathan")
                photo = Photo.find("nathan_photo_1")
                @camera = Camera.find(photo[:camera_id])
                @composite_tuple = join.find(Photo[:id].eq(photo[:id]))
                join.tuples.should include(composite_tuple)
              end

              context "when the update causes the CompositeTuple to not match the #predicate" do
                it "removes the Tuple from the result of #tuples" do
                  join.should include(composite_tuple)
                  camera[:id] = "el_camera_loco"
                  join.should_not include(composite_tuple)
                end

                it "triggers the on_delete event" do
                  deleted = []
                  join.on_delete(retainer) do |tuple|
                    deleted.push tuple
                  end
                  camera[:id] = "el_camera_loco"
                  deleted.should include(composite_tuple)
                end

                it "releases the CompositeTuple" do
                  composite_tuple.should be_retained_by(join)
                  camera[:id] = "el_camera_loco"
                  composite_tuple.should_not be_retained_by(join)
                end
              end

              context "when the composite Tuple continues to match the #predicate after the update" do
                it "does not remove that composite Tuple from the results of #tuples" do
                  join.should include(composite_tuple)
                  camera[:name] = "A great naked camera"
                  join.should include(composite_tuple)
                end

                it "triggers the on_tuple_update event for the CompositeTuple" do
                  updated = []
                  join.on_tuple_update(retainer) do |tuple, attribute, old_value, new_value|
                    updated.push [tuple, attribute, old_value, new_value]
                  end
                  old_value = camera[:name]
                  new_value = "A great naked camera"
                  camera[:name] = new_value
                  updated.should include([composite_tuple, Camera[:name], old_value, new_value])
                end

                it "does not trigger the on_insert or on_delete event" do
                  join.on_insert(retainer) do |tuple|
                    raise "Don't taze me bro"
                  end
                  join.on_delete(retainer) do |tuple|
                    raise "Don't taze me bro"
                  end
                  camera[:name] = "A great naked camera"
                end
              end
            end
          end
        end
      end
    end
  end
end
