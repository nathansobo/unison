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

      describe "#find" do
        it "returns a singleton Selection with id equal to the passed in id" do
          users_set.find(1).should == users_set.where(users_set[:id].eq(1))
          users_set.find(1).should be_singleton
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
          @relation = users_set.where(Predicates::Eq.new(true, true)).retain(Object.new)
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

      describe "#retain" do
        context "when invoked for the first time" do
          attr_reader :relation
          before do
            @relation = users_set.where(Predicates::Eq.new(true, true))
            class << relation
              public :tuples, :initial_read
            end
          end

          it "inserts each of the results of #initial_read" do
            user_1 = users_set.find(1)
            user_2 = users_set.find(2)

            stub(relation).initial_read {[user_1, user_2]}
            mock.proxy(relation).insert(user_1).ordered
            mock.proxy(relation).insert(user_2).ordered

            relation.retain(Object.new)

            relation.tuples.should == relation.initial_read
            relation.tuples.object_id.should == relation.tuples.object_id
          end
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
