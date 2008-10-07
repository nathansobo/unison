require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Relations
    describe Relation do
      attr_reader :relation

      describe "#[]" do
        before do
          @relation = users_set
        end

        context "when passed a Symbol" do
          it "returns the result of #attribute" do
            relation[:id].should_not be_nil
            relation[:id].should == relation.attribute(:id)
          end
        end

        context "when passed an Integer" do
          it "returns the result of #tuples.[]" do
            relation[1].should_not be_nil
            relation[1].should == relation.tuples[1]
          end
        end

        context "when passed an unsupported argument" do
          it "raises an ArgumentError" do
            lambda do
              relation[Object.new]
            end.should raise_error(ArgumentError)
          end
        end
      end

      describe "#push" do
        before do
          @relation = users_set
        end

        it "calls push(self) on the passed in Repository" do
          repository = Repository.new(connection)
          mock.proxy(repository).push(relation)
          relation.push(repository)
        end

        it "defaults the Repository to Unison.origin" do
          mock.proxy(origin).push(relation)
          relation.push
        end
      end

      describe "#pull" do
        it "#merges the results of #fetch on the given Repository" do
          repository = Repository.new(connection)
          new_users = origin.fetch(users_set)
          mock.proxy(repository).fetch(users_set)
          mock.proxy(users_set).merge(new_users)

          new_users.each { |user| users_set.find(user.id).should be_nil }
          users_set.pull(repository)
          new_users.each { |user| users_set.find(user.id).should_not be_nil }
        end

        it "defaults the Repository to Unison.origin" do
          new_users = origin.fetch(users_set)
          mock.proxy(origin).fetch(users_set)
          mock.proxy(users_set).merge(new_users)

          new_users.each { |user| users_set.find(user.id).should be_nil }
          users_set.pull
          new_users.each { |user| users_set.find(user.id).should_not be_nil }
        end
      end

      describe "#compound?" do
        context "when #composed_sets.size == 1" do
          it "returns true" do
            users_set.composed_sets.size.should == 1
            users_set.should_not be_compound
          end
        end

        context "when #composed_sets.size is > 1" do
          it "returns false" do
            join = users_set.join(photos_set).on(photos_set[:user_id].eq(users_set[:id]))
            join.composed_sets.size.should == 2
            join.should be_compound
          end
        end
      end

      describe "#find" do
        context "when passed a Predicate" do
          context "when the Predicate results in a Selection that is not empty" do
            it "returns the first matching Tuple" do
              result = users_set.find(users_set[:id].eq("nathan"))
              result.class.should == User
              result.id.should == "nathan"
            end
          end

          context "when the Predicate results in a Selection that is empty" do
            it "returns nil" do
              users_set.find(users_set[:id].eq("not_in_set")).class.should == NilClass
            end
          end
        end

        context "when passed an id" do
          it "calls self[:id].convert on the argument" do
            mock.proxy(users_set[:id]).convert("nathan")
            users_set.find("nathan")
          end

          context "when a Tuple with the given #id is in the Relation" do
            before do
              users_set.where(users_set[:id].eq("nathan")).should_not be_empty
            end

            it "returns that Tuple" do
              user = users_set.find("nathan")
              user[:id].should == "nathan"
            end
          end

          context "when no Tuple with the given #id is in the Relation" do
            before do
              users_set.where(users_set[:id].eq("not_in_set")).should be_empty
            end

            it "returns that Tuple" do
              user = users_set.find("not_in_set")
              user.should be_nil
            end
          end
        end
      end

      describe "#singleton" do
        attr_reader :user
        before do
          @user = User.find("nathan")
          @relation = users_set.where(users_set[:id].eq("nathan"))
        end

        it "returns an instance of a SingletonRelation with self as the #operand" do
          relation.singleton.should == SingletonRelation.new(relation)
        end
      end

      describe "#where" do
        it "returns a Selection with self as its #operand and the given predicate as its #predicate" do
          selection = users_set.where(users_set[:id].eq("nathan"))
          selection.should be_an_instance_of(Selection)
          selection.operand.should == users_set
          selection.predicate.should == users_set[:id].eq("nathan")
        end
      end

      describe "#join" do
        it "returns a PartialInnerJoin with the argument as #operand_2 and the receiver as #operand_1" do
          expected_join = users_set.join(photos_set).on(users_set[:id].eq(photos_set[:user_id]))
          users_set.join(photos_set).on(users_set[:id].eq(photos_set[:user_id])).should == expected_join
        end
      end

      describe "#project" do

        context "when passed a Set" do
          it "returns a SetProjection with the receiver as #operand and the argument as #projected_set" do
            join = users_set.join(photos_set).on(users_set[:id].eq(photos_set[:user_id]))
            join.project(photos_set).should == SetProjection.new(join, photos_set)
          end
        end

        context "when passed an Attribute" do
          it "returns an AttributeProjection with the receiver as #operand and a singleton Array containing the argument as #projected_attributes" do
            users_set.project(:id).should == AttributesProjection.new(users_set, [:id])
          end
        end

        context "when passed an Array of Attributes" do
          it "returns an AttributeProjection with the receiver as #operand and an Array containing the arguments as #projected_attributes" do
            users_set.project(:id, :name).should == AttributesProjection.new(users_set, [:id, :name])
          end
        end
      end

      describe "#order_by" do
        it "returns an Ordering with the receiver as #operand and the argument as #attribute" do
          users_set.order_by(users_set[:name], users_set[:id]).should == Ordering.new(users_set, users_set[:name], users_set[:id])
        end
      end

      describe "#nil?" do
        it "always returns false even when #tuples is empty" do
          users_set.where(users_set[:id].eq("nathan")).should_not be_nil
          users_set.where(users_set[:id].eq("not_in_set")).should be_empty
          users_set.where(users_set[:id].eq("not_in_set")).should_not be_nil
        end
      end

      describe "#==" do
        before do
          @relation = users_set.where(Predicates::EqualTo.new(true, true))
        end

        context "when passed the same Set" do
          it "returns true" do
            relation.should == relation
          end
        end

        context "when passed a different Set" do
          attr_reader :other_relation
          context "with the same result of #tuples" do
            before do
              @other_relation = relation.where(Predicates::EqualTo.new(true, true))
              relation.tuples.should == other_relation.tuples
            end

            it "returns true" do
              relation.should == other_relation
            end
          end

          context "with the a different result of #tuples" do
            before do
              predicate = users_set[:id].eq("nathan")
              @other_relation = relation.where(predicate)
              other_relation.should_not be_empty
              relation.tuples.should_not == other_relation.tuples
            end

            it "returns false" do
              relation.should_not == other_relation
            end
          end
        end

        context "when an Array == to #tuples" do
          it "returns true" do
            relation.should == relation.tuples
          end
        end
      end

      describe "#after_first_retain" do
        attr_reader :relation
        before do
          @relation = users_set.where(Predicates::EqualTo.new(true, true))
          publicize relation, :tuples, :initial_read
        end

        it "inserts each of the results of #initial_read" do
          mock.proxy(relation).after_first_retain

          user_1 = users_set.find("nathan")
          user_2 = users_set.find("corey")

          stub(relation).initial_read {[user_1, user_2]}
          mock.proxy(relation).insert(user_1).ordered
          mock.proxy(relation).insert(user_2).ordered

          relation.retain_with(Object.new)

          relation.tuples.should == relation.initial_read
          relation.tuples.object_id.should == relation.tuples.object_id
        end
      end

      context "when #retained?" do
        attr_reader :retainer
        before do
          @retainer = Object.new
          @relation = users_set.where(Predicates::EqualTo.new(true, true)).retain_with(retainer)
          publicize relation, :tuples, :initial_read
        end

        describe "#on_insert" do
          it "returns a Subscription" do
            relation.on_insert(retainer) {}.class.should == Subscription
          end
        end

        describe "#on_delete" do
          it "returns a Subscription" do
            relation.on_delete(retainer) {}.class.should == Subscription
          end
        end

        describe "#on_tuple_update" do
          it "returns a Subscription" do
            relation.on_tuple_update(retainer) {}.class.should == Subscription
          end
        end

        describe "#tuples" do
          it "returns the contents of @tuples without calling #initial_read" do
            dont_allow(relation).initial_read
            relation.tuples.should_not be_empty
          end
        end

        describe "#after_last_release" do
          it "releases all #tuples" do
            relation.should be_retained
            relation.tuples.each do |tuple|
              tuple.should be_retained_by(relation)
            end

            relation.release_from(retainer)

            relation.should_not be_retained
            relation.tuples.each do |tuple|
              tuple.should_not be_retained_by(relation)
            end
          end
        end
      end

      context "when not #retained?" do
        attr_reader :retainer
        before do
          @retainer = Object.new
          @relation = users_set.where(Predicates::EqualTo.new(true, true))
          publicize relation, :tuples, :initial_read
        end

        describe "#on_insert" do
          it "raises an Error" do
            lambda do
              relation.on_insert(retainer) {}
            end.should raise_error("Relation must be retained")
          end
        end

        describe "#on_delete" do
          it "raises an Error" do
            lambda do
              relation.on_delete(retainer) {}
            end.should raise_error("Relation must be retained")
          end
        end

        describe "#on_tuple_update" do
          it "raises an Error" do
            lambda do
              relation.on_tuple_update(retainer) {}
            end.should raise_error("Relation must be retained")
          end
        end

        describe "#tuples" do
          it "returns the result of #initial_read" do
            mock(relation).initial_read {[:initial, :read, :result]}
            relation.tuples.should == [:initial, :read, :result]
          end
        end
      end

      describe "an Array of Relations" do
        describe ".flatten" do
          it "reduces to an Array of all the Relations' #tuples" do
            [users_set, photos_set].flatten.should == (users_set.tuples + photos_set.tuples)
          end
        end
      end
    end
  end
end
