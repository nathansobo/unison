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

      describe "#first" do
        it "returns the first tuple from #read" do
          users_set.first.should == users_set.read.first
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
      end

      describe "#retain" do
        before do
          @relation = users_set
        end

        context "when passing in a retainer for the first time" do
          it "increments #refcount by 1" do
            lambda do
              relation.retain(Object.new)
            end.should change {relation.refcount}.by(1)
          end

          it "causes #retained_by? to return true for the retainer" do
            retainer = Object.new
            relation.should_not be_retained_by(retainer)
            relation.retain(retainer)
            relation.should be_retained_by(retainer)
          end
        end

        context "when passing in a retainer for the second time" do
          it "raises an ArgumentError" do
            retainer = Object.new
            relation.retain(retainer)

            lambda do
              relation.retain(retainer)
            end.should raise_error(ArgumentError)
          end
        end
      end

      describe "#release" do
        attr_reader :retainer
        before do
          @relation = users_set
          @retainer = Object.new
          relation.retain(retainer)
          relation.should be_retained_by(retainer)
        end

        it "causes #retained_by(retainer) to return false" do
          relation.release(retainer)
          relation.should_not be_retained_by(retainer)
        end

        it "decrements #refcount by 1" do
          lambda do
            relation.release(retainer)
          end.should change {relation.refcount}.by(-1)
        end

        context "when #refcount becomes > 0" do
          it "does not call #destroy on itself" do
            relation.refcount.should be > 1
            dont_allow(relation).destroy
            relation.release(retainer)
          end
        end

        context "when #refcount becomes 0" do
          before do
            @relation = users_set.where(users_set[:id].eq(1))
            relation.retain(retainer)
            relation.refcount.should == 1
          end

          it "calls #destroy on itself" do
            mock.proxy(relation).destroy
            relation.release(retainer)
          end
        end
      end

      describe "#on_insert" do
        before do
          @relation = users_set
        end

        it "returns a Subscription" do
          relation.on_insert {}.class.should == Subscription
        end
      end

      describe "#on_delete" do
        before do
          @relation = users_set
        end

        it "returns a Subscription" do
          relation.on_delete {}.class.should == Subscription
        end
      end

      describe "#on_tuple_update" do
        before do
          @relation = users_set
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
