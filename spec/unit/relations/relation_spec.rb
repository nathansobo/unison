require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

module Unison
  module Relations
    describe Relation do
      attr_reader :relation

      describe "#where" do
        it "returns a Selection with self as its #operand and the given predicate as its #predicate" do
          selection = users_set.where(users_set[:id].eq(1))
          selection.should be_an_instance_of(Selection)
          selection.operand.should == users_set
          selection.predicate.should == users_set[:id].eq(1)
        end
      end

      describe "#nil?" do
        context "when the Relation is a singleton" do
          context "when #read.first is nil" do
            it "returns true" do
              selection = users_set.where(users_set[:id].eq(100))
              selection.treat_as_singleton

              selection.read.first.should be_nil
              selection.should be_nil
            end
          end

          context "when #read.first is not nil" do
            it "returns false" do
              selection = users_set.where(users_set[:id].eq(1))
              selection.treat_as_singleton

              selection.read.first.should_not be_nil
              selection.should_not be_nil
            end
          end
        end

        context "when the Relation is not a singleton" do
          it "always returns false even when #read is empty" do
            users_set.where(users_set[:id].eq(1)).should_not be_nil
            users_set.where(users_set[:id].eq(100)).should be_empty
            users_set.where(users_set[:id].eq(100)).should_not be_nil
          end
        end
      end

      describe "#treat_as_singleton" do
        attr_reader :user
        before do
          @user = User.find(1)
          @relation = users_set.where(users_set[:id].eq(1))
          relation.should_not be_singleton
          relation.treat_as_singleton
        end

        it "causes #singleton? to be true" do
          relation.should be_singleton
        end

        it "forwards #method_missing to the first Tuple in the Relation" do
          mock(user).my_method {:return_value}
          relation.my_method.should == :return_value
        end

        it "returns self" do
          relation.treat_as_singleton.should == relation
        end
      end

      describe "#==" do
        before do
          @relation = Set.new(:users).retain(Object.new)
        end

        context "when passed the same Set" do
          it "returns true" do
            relation.should == relation
          end
        end

        context "when passed a different Set" do
          context "with the same result of #read" do
            it "returns true" do
              relation.should == Set.new(:users)
            end
          end

          context "with the a different result of #read" do
            it "returns false" do
              another_relation = Set.new(:users).retain(Object.new)
              another_relation.insert(User.new(:id => 100, :name => "Brian"))
              relation.should_not == another_relation
            end
          end
        end

        context "when an Array == to #read" do
          it "returns true" do
            relation.should == relation.read
          end
        end
      end

      describe "#read" do
        context "when the Relation is not retained" do
          before do
            @relation = Relations::Set.new(:unretained_set)
            relation.should_not be_retained
          end

          it "returns the result of #initial_read" do
            mock.proxy(relation).initial_read {[:initial, :read, :result]}
            relation.read.should == [:initial, :read, :result]
          end
        end

        context "when the Relation is retained" do
          before do
            @relation = users_set
            relation.should be_retained
          end

          it "returns the cached Tuples without calling #initial_read" do
            dont_allow(relation).initial_read
            relation.read.should == relation.tuples
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

            user = relation.read.first
            old_name = user[:name]
            user[:name] = "Another Name"
            arguments.should == [[user, users_set[:name], old_name, "Another Name"]]
          end
        end
      end
    end
  end
end
