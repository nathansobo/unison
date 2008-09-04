require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Relations
    describe Ordering do
      attr_reader :operand, :order_by_attribute, :ordering
      before do
        @operand = users_set
        @order_by_attribute = users_set[:name]
        @ordering = Ordering.new(operand, order_by_attribute)
      end

      describe "#initialize" do
        it "sets the #operand and #order_by_attribute" do
          ordering.operand.should == operand
          ordering.order_by_attribute.should == order_by_attribute
        end
      end

      describe "#to_sql" do
        it "returns the operand's SQL ordered by the #order_by_attribute" do
          ordering.to_sql.should be_like(<<-SQL)
            SELECT          `users`.`id`, `users`.`name`, `users`.`hobby`, `users`.`team_id`
            FROM            `users`
            ORDER BY       `users`.`name`
          SQL
        end
      end

      describe "#to_arel" do
        it "returns an Arel representation of the relation" do
          ordering.to_arel.should == operand.to_arel.order(order_by_attribute.to_arel)
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

        context "when the Ordering contains CompositeTuples" do
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

      describe "#attribute" do
        it "delegates to #operand" do
          operand_attribute = operand.attribute(:id)
          mock.proxy(operand).attribute(:id)
          ordering.attribute(:id).should == operand_attribute
        end
      end
      
      describe "#has_attribute?" do
        it "delegates to #operand" do
          operand.has_attribute?(:id).should be_true
          mock.proxy(operand).has_attribute?(:id)
          ordering.has_attribute?(:id).should be_true
        end
      end

      describe "when #retained?" do
        attr_reader :retainer
        before do
          @retainer = Object.new
          ordering.retained_by(retainer)
        end

        describe "when a Tuple is inserted into the #operand" do
          it "the Tuple is inserted into #tuples in a location consistent with the ordering" do
            operand.insert(User.new(:name => "Marcel", :hobby => "Dog Walking"))
            expected_tuples = operand.tuples.sort_by {|tuple| tuple[order_by_attribute]}
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
          describe "when the updated Attribute is the sort #order_by_attribute for the ordering" do
            it "relocates the updated Tuple in accordance with the ordering" do
              tuple_to_update = ordering.first
              tuple_to_update[order_by_attribute] = "Zarathustra"

              expected_tuples = operand.tuples.sort_by {|tuple| tuple[order_by_attribute]}
              ordering.tuples.should == expected_tuples          
            end
          end

          it "triggers the on_tuple_update event" do
            arguments = []
            ordering.on_tuple_update do |tuple, attribute, old_value, new_value|
              arguments.push [tuple, attribute, old_value, new_value]
            end

            tuple_to_update = operand.first
            old_value = tuple_to_update[order_by_attribute]
            new_value = "Marcel"
            new_value.should_not == old_value

            tuple_to_update[order_by_attribute] = new_value

            arguments.should == [[tuple_to_update, order_by_attribute, old_value, new_value]]
          end
        end

        describe "#after_last_release" do
          before do
            publicize ordering, :subscriptions
            publicize operand, :insert_subscription_node, :delete_subscription_node, :tuple_update_subscription_node
          end
          
          it "unsubscribes from and releases its #operand" do
            operand.should be_retained_by(ordering)

            ordering.should be_subscribed_to(operand.insert_subscription_node)
            ordering.should be_subscribed_to(operand.delete_subscription_node)
            ordering.should be_subscribed_to(operand.tuple_update_subscription_node)

            mock.proxy(ordering).after_last_release
            ordering.release(retainer)

            operand.should_not be_retained_by(ordering)
            ordering.should_not be_subscribed_to(operand.insert_subscription_node)
            ordering.should_not be_subscribed_to(operand.delete_subscription_node)
            ordering.should_not be_subscribed_to(operand.tuple_update_subscription_node)
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
            publicize ordering, :subscriptions
            ordering.subscriptions.should be_empty
            operand.should_not be_retained_by(ordering)

            mock.proxy(ordering).after_first_retain
            ordering.retained_by(Object.new)
            ordering.subscriptions.should_not be_empty
            operand.should be_retained_by(ordering)
          end

          it "retains the Tuples inserted by initial_read" do
            ordering.retained_by(Object.new)
            ordering.should_not be_empty
            ordering.each do |tuple|
              tuple.should be_retained_by(ordering)
            end
          end
        end

        describe "#tuples" do
          it "returns the #operand's #tuples, ordered by the #order_by_attribute" do
            tuples_in_expected_order = operand.tuples.sort_by {|tuple| tuple[order_by_attribute]}
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
