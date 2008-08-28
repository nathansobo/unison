require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

module Unison
  module Relations
    describe Ordering do
      attr_reader :operand, :attribute, :ordering
      before do
        @operand = users_set
        @attribute = users_set[:name]
        @ordering = Ordering.new(operand, attribute)
      end

      describe "#initialize" do
        it "sets the #operand and #attribute" do
          ordering.operand.should == operand
          ordering.attribute.should == attribute
        end
      end

      describe "#to_sql" do
        it "returns the operand's SQL ordered by the #attribute" do
          ordering.to_sql.should be_like(<<-SQL)
            SELECT          `users`.`id`, `users`.`name`, `users`.`hobby`
            FROM            `users`
            ORDER BY       `users`.`name`
          SQL
        end
      end

      describe "#to_arel" do
        it "returns an Arel representation of the relation" do
          ordering.to_arel.should == operand.to_arel.order(attribute.to_arel)
        end
      end

      describe "#tuple_class" do
        it "delegates to its #operand" do
          ordering.tuple_class.should == operand.tuple_class
        end
      end

      describe "#set" do
        it "delegates to its #operand" do
          ordering.set.should == operand.set
        end
      end

      describe "#push" do
        before do
          origin.connection[:users].delete
          origin.connection[:photos].delete
        end

        context "when the Ordering contains PrimitiveTuples" do
          before do
            ordering.composed_sets.length.should == 1
          end

          it "calls #push on the given Repository with self" do
            origin.fetch(ordering).should be_empty
            ordering.push(origin)
            origin.fetch(ordering).should == ordering.tuples
          end
        end

        context "when the Ordering contains CompoundTuples" do
          before do
            @ordering = users_set.join(photos_set).on(photos_set[:user_id].eq(users_set[:id])).order_by(users_set[:name])
            ordering.should_not be_empty
            ordering.composed_sets.length.should == 2
          end

          it "pushes a Projection of each Set represented in the Ordering to the given Repository" do
            users_projection = ordering.project(users_set)
            photos_projection = ordering.project(photos_set)
            mock.proxy(origin).push(users_projection)
            mock.proxy(origin).push(photos_projection)

            origin.fetch(users_projection).should be_empty
            origin.fetch(photos_projection).should be_empty
            ordering.push(origin)
            origin.fetch(users_projection).should == users_projection.tuples
            origin.fetch(photos_projection).should == photos_projection.tuples
          end
        end
      end


      describe "#composed_sets" do
        it "delegates to its #operand" do
          ordering.composed_sets.should == operand.composed_sets
        end
      end

      describe "when #retained?" do
        before do
          ordering.retain(Object.new)
        end

        describe "when a Tuple is inserted into the #operand" do
          it "the Tuple is inserted into #tuples in a location consistent with the ordering" do
            operand.insert(User.new(:name => "Marcel", :hobby => "Dog Walking"))
            expected_tuples = operand.tuples.sort_by {|tuple| tuple[attribute]}
            expected_tuples.should_not == operand.tuples
            ordering.tuples.should == expected_tuples
          end
        end

        describe "when a Tuple is deleted from the #operand" do
          it "the Tuple is deleted from #tuples" do
            user_to_delete = operand.first
            ordering.tuples.should include(user_to_delete)
            operand.delete(user_to_delete)
            ordering.tuples.should_not include(user_to_delete)
          end
        end

        describe "when a Tuple is updated in the #operand" do
          describe "when the updated Attribute is the sort #attribute for the ordering" do
            it "relocates the updated Tuple in accordance with the ordering" do
              tuple_to_update = ordering.first
              tuple_to_update[attribute] = "Zarathustra"

              expected_tuples = operand.tuples.sort_by {|tuple| tuple[attribute]}
              ordering.tuples.should == expected_tuples          
            end
          end

          it "triggers the on_tuple_update event" do
            arguments = []
            ordering.on_tuple_update do |tuple, attribute, old_value, new_value|
              arguments.push [tuple, attribute, old_value, new_value]
            end

            tuple_to_update = operand.first
            old_value = tuple_to_update[attribute]
            new_value = "Marcel"
            new_value.should_not == old_value

            tuple_to_update[attribute] = new_value

            arguments.should == [[tuple_to_update, attribute, old_value, new_value]]
          end
        end

        describe "#after_last_release" do
          it "unsubscribes from and releases its #operand" do
            class << ordering
              public :after_last_release
            end

            ordering.operand_subscriptions.should_not be_empty
            operand.should be_retained_by(ordering)

            ordering.operand_subscriptions.each do |subscription|
              operand.subscriptions.should include(subscription)
            end

            ordering.after_last_release

            operand.should_not be_retained_by(ordering)
            ordering.operand_subscriptions.each do |subscription|
              operand.subscriptions.should_not include(subscription)
            end
          end
        end

        describe "#merge" do
          it "calls #merge on the #operand" do
            tuple = User.new(:name => "Gottlob", :hobby => "Number Theory")
            operand.find(tuple[:id]).should be_nil
            mock.proxy(operand).merge([tuple])
            
            ordering.merge([tuple])

            operand.should include(tuple)
          end
        end
      end

      describe "when not #retained?" do
        describe "#after_first_retain" do
          it "retains and subscribes to its #operand" do
            ordering.operand_subscriptions.should be_empty
            operand.should_not be_retained_by(ordering)

            mock.proxy(ordering).after_first_retain
            ordering.retain(Object.new)
            ordering.operand_subscriptions.should_not be_empty
            operand.should be_retained_by(ordering)
          end

          it "retains the Tuples inserted by initial_read" do
            ordering.retain(Object.new)
            ordering.should_not be_empty
            ordering.each do |tuple|
              tuple.should be_retained_by(ordering)
            end
          end
        end

        describe "#tuples" do
          it "returns the #operand's #tuples, ordered by the #attribute" do
            tuples_in_expected_order = operand.tuples.sort_by {|tuple| tuple[attribute]}
            tuples_in_expected_order.should_not == operand.tuples
            ordering.tuples.should == tuples_in_expected_order
          end
        end

        describe "#merge" do
          it "raises an Exception" do
            lambda do
              ordering.merge([User.new(:name => "Bertrand", :hobby => "Analytic Philosophy")])
            end.should raise_error
          end
        end
      end
    end
  end
end
