require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

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

      describe "#pull" do
        it "#merges the results of #fetch on the given Repository" do
          new_users = origin.fetch(users_set)
          mock.proxy(origin).fetch(users_set)
          mock.proxy(users_set).merge(new_users)

          new_users.each { |user| users_set.find(user.id).should be_nil }
          users_set.pull(origin)
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
        context "when a Tuple with the given #id is in the Relation" do
          before do
            users_set.where(users_set[:id].eq(1)).should_not be_empty
          end

          it "returns that Tuple" do
            user = users_set.find(1)
            user[:id].should == 1
          end
        end

        context "when no Tuple with the given #id is in the Relation" do
          before do
            users_set.where(users_set[:id].eq(100)).should be_empty
          end

          it "returns that Tuple" do
            user = users_set.find(100)
            user.should be_nil
          end
        end
      end

      describe "#where" do
        it "returns a Selection with self as its #operand and the given predicate as its #predicate" do
          selection = users_set.where(users_set[:id].eq(1))
          selection.should be_an_instance_of(Selection)
          selection.operand.should == users_set
          selection.predicate.should == users_set[:id].eq(1)
        end
      end

      describe "#join" do
        it "returns a PartialInnerJoin with the argument as #operand_2 and the receiver as #operand_1" do
          expected_join = users_set.join(photos_set).on(users_set[:id].eq(photos_set[:user_id]))
          users_set.join(photos_set).on(users_set[:id].eq(photos_set[:user_id])).should == expected_join
        end
      end

      describe "#project" do
        it "returns a Projection with the receiver as #operand and the argument as #attributes" do
          join = users_set.join(photos_set).on(users_set[:id].eq(photos_set[:user_id]))
          join.project(photos_set).should == Projection.new(join, photos_set)
        end
      end

      describe "#order_by" do
        it "returns an Ordering with the receiver as #operand and the argument as #attribute" do
          users_set.order_by(users_set[:name]).should == Ordering.new(users_set, users_set[:name])
        end
      end

      describe "#nil?" do
        context "when the Relation is a singleton" do
          context "when #tuples.first is nil" do
            it "returns true" do
              selection = users_set.where(users_set[:id].eq(100))
              selection.singleton

              selection.tuples.first.should be_nil
              selection.should be_nil
            end
          end

          context "when #tuples.first is not nil" do
            it "returns false" do
              selection = users_set.where(users_set[:id].eq(1))
              selection.singleton

              selection.tuples.first.should_not be_nil
              selection.should_not be_nil
            end
          end
        end

        context "when the Relation is not a singleton" do
          it "always returns false even when #tuples is empty" do
            users_set.where(users_set[:id].eq(1)).should_not be_nil
            users_set.where(users_set[:id].eq(100)).should be_empty
            users_set.where(users_set[:id].eq(100)).should_not be_nil
          end
        end
      end

      describe "#singleton" do
        attr_reader :user
        before do
          @user = User.find(1)
          @relation = users_set.where(users_set[:id].eq(1))
          relation.should_not be_singleton
        end

        it "causes #singleton? to be true" do
          relation.singleton          
          relation.should be_singleton
        end

        it "forwards #method_missing to the first Tuple in the Relation" do
          mock(user).my_method {:return_value}
          relation.singleton
          relation.my_method.should == :return_value
        end

        it "returns self" do
          relation.singleton.should == relation
        end
      end

      describe "#tuple" do
        before do
          @relation = users_set.where(users_set[:id].eq(1))
        end

        context "when singleton? is true" do
          before do
            relation.singleton
          end

          it "returns #tuples.first" do
            relation.tuple.should == relation.tuples.first
          end
        end

        context "when singleton? is false" do
          before do
            relation.should_not be_singleton
          end

          it "raises an Exception" do
            lambda do
              relation.tuple
            end.should raise_error
          end
        end
      end

      describe "#==" do
        before do
          @relation = users_set.where(Predicates::Eq.new(true, true))
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
              @other_relation = relation.where(Predicates::Eq.new(true, true))
              relation.tuples.should == other_relation.tuples
            end

            it "returns true" do
              relation.should == other_relation
            end
          end

          context "with the a different result of #tuples" do
            before do
              predicate = users_set[:id].eq(1)
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


      context "when #retained?" do
        before do
          @relation = users_set.where(Predicates::Eq.new(true, true)).retained_by(Object.new)
          class << relation
            public :tuples, :initial_read
          end
        end

      end


      describe "#tuples" do
        context "when the Relation is not retained" do
          before do
            @relation = Relations::Set.new(:unretained_set)
            relation.has_attribute(:id, :integer)
            relation.should_not be_retained
          end

          it "returns the result of #initial_read" do
            mock(relation).initial_read {[:initial, :read, :result]}
            relation.tuples.should == [:initial, :read, :result]
          end
        end

        context "when the Relation is retained" do
          before do
            @relation = users_set
            relation.should be_retained
          end

          it "returns the contents of @tuples without calling #initial_read" do
            dont_allow(relation).initial_read
            relation.tuples.should_not be_empty
          end
        end
      end

      describe "#after_first_retain" do
        attr_reader :relation
        before do
          @relation = users_set.where(Predicates::Eq.new(true, true))
          class << relation
            public :tuples, :initial_read
          end
        end

        it "inserts each of the results of #initial_read" do
          mock.proxy(relation).after_first_retain

          user_1 = users_set.find(1)
          user_2 = users_set.find(2)

          stub(relation).initial_read {[user_1, user_2]}
          mock.proxy(relation).insert(user_1).ordered
          mock.proxy(relation).insert(user_2).ordered

          relation.retained_by(Object.new)

          relation.tuples.should == relation.initial_read
          relation.tuples.object_id.should == relation.tuples.object_id
        end
      end

      describe "#on_insert" do
        context "when Relation is not retained" do
          before do
            @relation = Relations::Set.new(:unretained_set)
            relation.should_not be_retained
          end

          it "raises an Error" do
            lambda do
              relation.on_insert {}
            end.should raise_error
          end
        end

        context "when Relation is retained" do
          before do
            @relation = users_set
            relation.should be_retained            
          end

          it "returns a Subscription" do
            relation.on_insert {}.class.should == Subscription
          end
        end
      end

      describe "#on_delete" do
        context "when Relation is not retained" do
          before do
            @relation = Relations::Set.new(:unretained_set)
            relation.should_not be_retained
          end

          it "raises an Error" do
            lambda do
              relation.on_delete {}
            end.should raise_error
          end
        end

        context "when Relation is retained" do
          before do
            @relation = users_set
            relation.should be_retained
          end

          it "returns a Subscription" do
            relation.on_delete {}.class.should == Subscription
          end
        end
      end

      describe "#on_tuple_update" do
        context "when Relation is not retained" do
          before do
            @relation = Relations::Set.new(:unretained_set)
            relation.should_not be_retained
          end

          it "raises an Error" do
            lambda do
              relation.on_tuple_update {}
            end.should raise_error
          end
        end

        context "when Relation is retained" do
          before do
            @relation = users_set
            relation.should be_retained
          end

          it "returns a Subscription" do
            relation.on_tuple_update {}.class.should == Subscription
          end

          it "invokes the block with the (Attribute, old_value, new_value) when a member Tuple is updated" do
            arguments = []
            relation.on_tuple_update do |tuple, attribute, old_value, new_value|
              arguments.push [tuple, attribute, old_value, new_value]
            end

            user = relation.tuples.first
            old_name = user[:name]
            user[:name] = "Another Name"
            arguments.should == [[user, users_set[:name], old_name, "Another Name"]]
          end
        end
      end
    end
  end
end
