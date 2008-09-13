require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Relations
    describe SingletonRelation do
      attr_reader :operand, :singleton_relation
      before do
        @operand = accounts_set.order_by(accounts_set[:employee_id])
        @singleton_relation = SingletonRelation.new(operand)
      end

      describe "#initialize" do
        it "sets the #operand" do
          singleton_relation.operand.should == accounts_set
        end
      end

      describe "#tuple_class" do
        it "delegates to its #operand" do
          singleton_relation.tuple_class.should == operand.tuple_class
        end
      end

      describe "#method_missing" do
        it "delegates to #tuple" do
          mock(singleton_relation.tuple).foo(1, 2)
          singleton_relation.foo(1, 2)
        end
      end

      describe "#tuple" do
        it "returns #operand.tuples.first" do
          singleton_relation.tuple.should == operand.tuples.first
        end
      end

      describe "#nil?" do
        it "delegates to #tuple" do
          mock.proxy(singleton_relation.tuple).nil?
          singleton_relation.nil?
        end
      end

      describe "#push" do
        before do
          origin.connection[:users].delete
          origin.connection[:accounts].delete
        end

        context "when the SingletonRelation contains PrimitiveTuples" do
          before do
            singleton_relation.composed_sets.length.should == 1
          end

          it "calls #push on the given Repository with self" do
            origin.fetch(singleton_relation).should be_empty
            singleton_relation.push(origin)
            origin.fetch(singleton_relation).should == singleton_relation.tuples
          end
        end

        context "when the SingletonRelation contains CompositeTuples" do
          before do
            @singleton_relation = users_set.join(accounts_set).on(accounts_set[:user_id].eq(users_set[:id])).where(users_set[:id].eq("nathan"))
            singleton_relation.should_not be_empty
            singleton_relation.composed_sets.length.should == 2
          end

          it "pushes a Projection of each Set represented in the SingletonRelation to the given Repository" do
            users_projection = singleton_relation.project(users_set)
            accounts_projection = singleton_relation.project(accounts_set)
            mock.proxy(origin).push(users_projection)
            mock.proxy(origin).push(accounts_projection)

            origin.fetch(users_projection).should be_empty
            origin.fetch(accounts_projection).should be_empty
            singleton_relation.push(origin)
            origin.fetch(users_projection).should == users_projection.tuples
            origin.fetch(accounts_projection).should == accounts_projection.tuples
          end
        end
      end

      describe "#to_sql" do
        context "when #operand is a Set" do
          it "returns 'select #operand where #predicate'" do
            singleton_relation.to_sql.should be_like("SELECT `accounts`.`id`, `accounts`.`user_id`, `accounts`.`name`, `accounts`.`deactivated_at`, `accounts`.`employee_id` FROM `accounts` ORDER BY `accounts`.`employee_id` LIMIT 1")
          end
        end
      end

      describe "#to_arel" do
        it "returns an Arel representation of the relation" do
          singleton_relation.to_arel.should == operand.to_arel.take(1)
        end
      end

      describe "#set" do
        it "delegates to its #operand" do
          singleton_relation.set.should == operand.set
        end
      end

      describe "#composed_sets" do
        it "delegates to its #operand" do
          singleton_relation.composed_sets.should == operand.composed_sets
        end
      end

      describe "#attribute" do
        it "delegates to #operand" do
          operand_attribute = operand.attribute(:id)
          mock.proxy(operand).attribute(:id)
          singleton_relation.attribute(:id).should == operand_attribute
        end
      end

      describe "#has_attribute?" do
        it "delegates to #operand" do
          operand.has_attribute?(:id).should be_true
          mock.proxy(operand).has_attribute?(:id)
          singleton_relation.has_attribute?(:id).should be_true
        end
      end

      context "when #retained?" do
        attr_reader :retainer
        before do
          @retainer = Object.new
          singleton_relation.retain_with(retainer)
          singleton_relation.tuples
        end

        describe "#merge" do
          it "calls #merge on the #operand" do
            tuple = Account.new(:employee_id => 0)
            operand.find(tuple[:id]).should be_nil
            operand.should_not include(tuple)
            mock.proxy(operand).merge([tuple])

            singleton_relation.merge([tuple])

            operand.should include(tuple)
          end
        end

        context "when a Tuple is inserted into the #operand" do
          context "when the Tuple is first in the #operand" do
            attr_reader :old_first_tuple, :new_first_tuple

            before do
              @old_first_tuple = singleton_relation.tuple
              @new_first_tuple = Account.new(:employee_id => old_first_tuple.employee_id - 1)
            end

            it "sets #tuple to the inserted Tuple" do
              accounts_set.insert(new_first_tuple)
              operand.tuples.should include(new_first_tuple)              
              singleton_relation.tuple.should == new_first_tuple
            end
            
            it "triggers the on_insert event with the inserted Tuple after the #tuple has changed" do
              on_insert_tuple = nil
              singleton_relation.on_insert(retainer) do |tuple|
                singleton_relation.tuple.should == new_first_tuple
                on_insert_tuple = tuple
              end
              operand.set.insert(new_first_tuple)
              on_insert_tuple.should == new_first_tuple
            end

            it "retains the inserted Tuple" do
              new_first_tuple.should_not be_retained_by(singleton_relation)
              operand.set.insert(new_first_tuple)
              new_first_tuple.should be_retained_by(singleton_relation)
            end

            it "triggers the on_delete event with the old #tuple after the #tuple has changed" do
              on_delete_tuple = nil
              singleton_relation.on_delete(retainer) do |tuple|
                singleton_relation.tuple.should == new_first_tuple
                on_delete_tuple = tuple
              end
              operand.set.insert(new_first_tuple)
              on_delete_tuple.should == old_first_tuple
            end

            it "releases the old value of #tuple" do
              old_first_tuple.should be_retained_by(singleton_relation)
              operand.set.insert(new_first_tuple)
              old_first_tuple.should_not be_retained_by(singleton_relation)
            end
          end

          context "when the Tuple is not first in the #operand" do
            attr_reader :first_tuple, :new_tuple
            before do
              @first_tuple = singleton_relation.tuple
              @new_tuple = Account.new(:employee_id => first_tuple.employee_id + 1)
            end

            it "does not change #tuple" do
              operand.set.insert(new_tuple)
              singleton_relation.tuple.should == first_tuple
            end

            it "does not trigger the on_insert event" do
              singleton_relation.on_insert(retainer) do
                raise "Dont call me"
              end
              operand.set.insert(new_tuple)
            end

            it "does not trigger the on_delete event" do
              singleton_relation.on_delete(retainer) do
                raise "Dont call me"
              end
              operand.set.insert(new_tuple)
            end
          end          
        end

        context "when a Tuple in the #operand is updated" do
          context "when the Tuple is first in the #operand" do

          end

          context "when the Tuple is not first in the #operand" do

          end
        end

        context "when a Tuple is inserted from the #operand" do
          context "when the Tuple was first in the #operand" do

          end

          context "when the Tuple was not first in the #operand" do

          end
        end
      end

      context "when not #retained?" do
        describe "#after_first_retain" do
          before do
            mock.proxy(singleton_relation).after_first_retain
          end

          it "retains the Tuples inserted by #initial_read" do
            singleton_relation.retain_with(Object.new)
            singleton_relation.tuples.should_not be_empty
            singleton_relation.tuples.each do |tuple|
              tuple.should be_retained_by(singleton_relation)
            end
          end
        end

        describe "#tuple" do
          it "returns #operand.tuples.first"
        end

        describe "#tuples" do
          it "returns [#operand.tuples.first]"
        end

        describe "#merge" do
          it "raises an Exception" do
            lambda do
              singleton_relation.merge([Photo.new(:id => "account_100", :user_id => "nathan", :name => "Photo 100")])
            end.should raise_error
          end
        end
      end
    end
  end
end