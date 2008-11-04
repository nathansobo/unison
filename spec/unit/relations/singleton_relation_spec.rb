require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Relations
    describe SingletonRelation do
      attr_reader :singleton_relation
      before do
        @singleton_relation = SingletonRelation.new(operand)
      end

      def operand
        @operand ||= accounts_set.order_by(accounts_set[:employee_id])
      end

      describe "#initialize" do
        it "sets the #operand" do
          operand.should == accounts_set
        end
      end

      describe "#tuple_class" do
        it "delegates to its #operand" do
          singleton_relation.tuple_class.should == operand.tuple_class
        end
      end

      describe "#new_tuple" do
        it "delegates to its #operand" do
          attributes = {:id => 1, :name => 'Laszlo Maholy-Nagy', :employee_id => 1}
          singleton_relation.new_tuple(attributes).should == operand.new_tuple(attributes)
        end
      end

      describe "#method_missing" do
        it "delegates to #tuple" do
          mock(singleton_relation.tuple).foo(1, 2)
          singleton_relation.foo(1, 2)
        end
      end

      describe "#singleton" do
        it "returns self" do
          singleton_relation.singleton.should equal(singleton_relation)
        end
      end

      describe "#tuple" do
        it "returns #operand.tuples.first" do
          singleton_relation.tuple.should == operand.tuples.first
        end
      end

      describe "#fetch" do
        def operand
          users_set
        end

        it "returns the #first of the Array returned by calling #fetch on Unison.origin with self" do
          expected_tuple = origin.fetch(singleton_relation).first
          expected_tuple.should_not be_nil
          singleton_relation.fetch.should == expected_tuple 
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
            singleton_relation.push
            origin.fetch(singleton_relation).should == singleton_relation.tuples
          end
        end

        context "when the SingletonRelation contains CompositeTuples" do
          before do
            @singleton_relation = users_set.join(accounts_set).on(accounts_set[:user_id].eq(users_set[:id])).where(users_set[:id].eq("nathan"))
            singleton_relation.should_not be_empty
            singleton_relation.composed_sets.length.should == 2
          end

          it "pushes a SetProjection of each Set represented in the SingletonRelation to the given Repository" do
            users_projection = singleton_relation.project(users_set)
            accounts_projection = singleton_relation.project(accounts_set)
            mock.proxy(origin).push(users_projection)
            mock.proxy(origin).push(accounts_projection)

            users_set.fetch.should be_empty
            accounts_set.fetch.should be_empty
            singleton_relation.push
            users_set.fetch.should == users_projection.tuples
            accounts_set.fetch.should == accounts_projection.tuples
          end
        end
      end

      describe "#fetch_sql" do
        context "when #operand is a Set" do
          it "returns 'select #operand where #predicate'" do
            singleton_relation.fetch_sql.should be_like("SELECT `accounts`.`id`, `accounts`.`user_id`, `accounts`.`name`, `accounts`.`deactivated_at`, `accounts`.`employee_id` FROM `accounts` ORDER BY `accounts`.`employee_id` LIMIT 1")
          end
        end
      end

      describe "#fetch_arel" do
        it "returns an Arel representation of the relation" do
          singleton_relation.fetch_arel.should == operand.fetch_arel.take(1)
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

      context "when #retained?" do
        attr_reader :retainer
        before do
          @retainer = Object.new
          singleton_relation.retain_with(retainer)
          singleton_relation.tuples
        end

        after do
          singleton_relation.release_from(retainer)
        end

        context "when a Tuple is inserted into the #operand" do
          context "when the Tuple is first in the #operand" do
            context "when #operand.tuples.size > 0" do
              attr_reader :old_first_tuple, :new_first_tuple
              before do
                @old_first_tuple = singleton_relation.tuple
                @new_first_tuple = Account.new(:employee_id => old_first_tuple.employee_id - 1)
              end

              it "sets #tuple to the inserted Tuple" do
                accounts_set.insert(new_first_tuple)
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

              it "triggers the on_delete event with the old #tuple after the #tuple has changed" do
                on_delete_tuple = nil
                singleton_relation.on_delete(retainer) do |tuple|
                  singleton_relation.tuple.should == new_first_tuple
                  on_delete_tuple = tuple
                end
                operand.set.insert(new_first_tuple)
                on_delete_tuple.should == old_first_tuple
              end

              it "retains the inserted Tuple" do
                new_first_tuple.should_not be_retained_by(singleton_relation)
                operand.set.insert(new_first_tuple)
                new_first_tuple.should be_retained_by(singleton_relation)
              end

              it "releases the old value of #tuple" do
                old_first_tuple.should be_retained_by(singleton_relation)
                operand.set.insert(new_first_tuple)
                old_first_tuple.should_not be_retained_by(singleton_relation)
              end

              it "triggers the on_change event with self" do
                on_change_arguments = []
                singleton_relation.on_change(retainer) do |*args|
                  on_change_arguments.push(args)
                end
                operand.set.insert(new_first_tuple)
                on_change_arguments.should == [[singleton_relation]]
              end
            end

            context "when #operand.tuples.size == 0" do
              attr_reader :new_first_tuple
              before do
                @new_first_tuple = Account.new(:employee_id => 999)
              end

              def operand
                @operand ||= accounts_set.where(accounts_set[:employee_id].eq(999))
              end

              it "sets #tuple to the inserted Tuple" do
                accounts_set.insert(new_first_tuple)
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

              it "does not trigger the on_delete event" do
                singleton_relation.on_delete(retainer) do |tuple|
                  raise "Don't taze me"
                end
                operand.set.insert(new_first_tuple)
              end

              it "retains the inserted Tuple" do
                new_first_tuple.should_not be_retained_by(singleton_relation)
                operand.set.insert(new_first_tuple)
                new_first_tuple.should be_retained_by(singleton_relation)
              end

              it "triggers the on_change event with self" do
                on_change_arguments = []
                singleton_relation.on_change(retainer) do |*args|
                  on_change_arguments.push(args)
                end
                operand.set.insert(new_first_tuple)
                on_change_arguments.should == [[singleton_relation]]
              end
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
                raise "Don't taze me"
              end
              operand.set.insert(new_tuple)
            end

            it "does not trigger the on_delete event" do
              singleton_relation.on_delete(retainer) do
                raise "Don't taze me"
              end
              operand.set.insert(new_tuple)
            end

            it "does not trigger the on_change event" do
              singleton_relation.on_change(retainer) do |*args|
                raise "Don't taze me bro"
              end
              operand.set.insert(new_tuple)
            end
          end          
        end
        
        context "when a Tuple is deleted from the #operand" do
          context "when the Tuple was first in the #operand" do
            attr_reader :old_first_tuple, :new_first_tuple

            context "when #operand.tuples.size > 1" do
              before do
                operand.tuples.size.should be > 1
                @old_first_tuple = singleton_relation.tuple
                @new_first_tuple = operand.tuples[1]
              end

              it "sets #tuple to the new value of #operand.tuples.first" do
                accounts_set.delete(old_first_tuple)
                singleton_relation.tuple.should == new_first_tuple
              end

              it "triggers the on_delete event with the deleted Tuple after the #tuple has changed" do
                on_delete_tuple = nil
                singleton_relation.on_delete(retainer) do |tuple|
                  singleton_relation.tuple.should == new_first_tuple
                  on_delete_tuple = tuple
                end
                operand.set.delete(old_first_tuple)
                on_delete_tuple.should == old_first_tuple
              end

              it "triggers the on_insert event with the new value of #tuple after the #tuple has changed" do
                on_insert_tuple = nil
                singleton_relation.on_insert(retainer) do |tuple|
                  singleton_relation.tuple.should == new_first_tuple
                  on_insert_tuple = tuple
                end
                operand.set.delete(old_first_tuple)
                on_insert_tuple.should == new_first_tuple
              end

              it "retains the new value of #tuple" do
                new_first_tuple.should_not be_retained_by(singleton_relation)
                operand.set.delete(old_first_tuple)
                new_first_tuple.should be_retained_by(singleton_relation)
              end              

              it "releases the old value of #tuple" do
                old_first_tuple.should be_retained_by(singleton_relation)
                operand.set.delete(old_first_tuple)
                old_first_tuple.should_not be_retained_by(singleton_relation)
              end

              it "triggers the on_change event with self" do
                on_change_arguments = []
                singleton_relation.on_change(retainer) do |*args|
                  on_change_arguments.push(args)
                end
                operand.set.delete(old_first_tuple)
                on_change_arguments.should == [[singleton_relation]]
              end
            end

            context "when #operand.tuples.size == 1" do
              before do
                operand.tuples.size.should == 1
                @old_first_tuple = operand.tuples.first
              end

              def operand
                @operand ||= accounts_set.where(accounts_set[:employee_id].eq(1))
              end

              it "sets #tuple to nil" do
                accounts_set.delete(old_first_tuple)
                operand.tuples.should be_empty
                singleton_relation.tuple.should be_nil
              end

              it "triggers the on_delete event with the deleted Tuple after the #tuple has changed" do
                on_delete_tuple = nil
                singleton_relation.on_delete(retainer) do |tuple|
                  singleton_relation.tuple.should == new_first_tuple
                  on_delete_tuple = tuple
                end
                operand.set.delete(old_first_tuple)
                on_delete_tuple.should == old_first_tuple
              end

              it "does not trigger the on_insert event" do
                singleton_relation.on_insert(retainer) do |tuple|
                  raise "Don't taze me"
                end
                operand.set.delete(old_first_tuple)
              end

              it "releases the old value of #tuple" do
                old_first_tuple.should be_retained_by(singleton_relation)
                operand.set.delete(old_first_tuple)
                old_first_tuple.should_not be_retained_by(singleton_relation)
              end

              it "triggers the on_change event with self" do
                on_change_arguments = []
                singleton_relation.on_change(retainer) do |*args|
                  on_change_arguments.push(args)
                end
                operand.set.delete(old_first_tuple)
                on_change_arguments.should == [[singleton_relation]]
              end
            end
          end

          context "when the Tuple was not first in the #operand" do
            attr_reader :first_tuple, :not_first_tuple
            before do
              @first_tuple = operand.tuples.first
              @not_first_tuple = operand.tuples[1]
              not_first_tuple.should_not == first_tuple
            end

            it "does not change #tuple" do
              operand.set.delete(not_first_tuple)
              singleton_relation.tuple.should == first_tuple
            end

            it "does not trigger the on_insert event" do
              singleton_relation.on_insert(retainer) do
                raise "Don't taze me"
              end
              operand.set.delete(not_first_tuple)
            end

            it "does not trigger the on_delete event" do
              singleton_relation.on_delete(retainer) do
                raise "Don't taze me"
              end
              operand.set.delete(not_first_tuple)
            end

            it "does not trigger the on_change event" do
              singleton_relation.on_change(retainer) do |*args|
                raise "Don't taze me bro"
              end
              operand.set.delete(not_first_tuple)
            end            
          end
        end

        context "when a Tuple in the #operand is updated" do
          context "when the Tuple is first in #operand" do
            attr_reader :updated_tuple
            before do
              @updated_tuple = singleton_relation.tuple
            end
            
            context "when the Tuple remains first in #operand" do
              attr_reader :old_name, :new_name
              before do
                @old_name = singleton_relation.tuple.name
                @new_name = "#{old_name} that is changed"
              end

              it "does not change #tuple" do
                updated_tuple.name = new_name
                singleton_relation.tuple.should == updated_tuple
              end

              it "triggers the on_tuple_update event with the inserted Tuple after the #tuple has changed" do
                on_tuple_update_arguments = []
                singleton_relation.on_tuple_update(retainer) do |tuple, attribute, old_value, new_value|
                  on_tuple_update_arguments.push([tuple, attribute, old_value, new_value])
                end
                updated_tuple.name = new_name
                on_tuple_update_arguments.should == [[updated_tuple, operand.set[:name], old_name, new_name]]
              end

              it "does not trigger the on_delete event" do
                singleton_relation.on_delete(retainer) do |*args|
                  raise "Don't taze me bro"
                end
                updated_tuple.name = new_name
              end

              it "does not trigger the on_insert event" do
                singleton_relation.on_insert(retainer) do |*args|
                  raise "Don't taze me bro"
                end
                updated_tuple.name = new_name
              end

              it "triggers the on_change event with self after the #tuple has changed" do
                on_change_arguments = []
                singleton_relation.on_change(retainer) do |*args|
                  on_change_arguments.push(args)
                end
                updated_tuple.name = new_name
                on_change_arguments.should == [[singleton_relation]]
              end
            end

            context "when the update causes the Tuple to no longer be the first in #operand" do
              it "changes #tuple to the new first Tuple in #operand" do
                updated_tuple.employee_id = 9999
                operand.tuples.first.should_not == updated_tuple
                singleton_relation.tuple.should == operand.tuples.first
              end
              
              it "does not trigger the on_tuple_update event" do
                singleton_relation.on_tuple_update(retainer) do
                  raise "Don't taze me bro"
                end
                updated_tuple.employee_id = 9999
                operand.tuples.first.should_not == updated_tuple
              end

              it "triggers the on_delete event with the updated Tuple" do
                on_delete_args = []
                singleton_relation.on_delete(retainer) do |*args|
                  on_delete_args.push(args)
                end
                updated_tuple.employee_id = 9999
                operand.tuples.first.should_not == updated_tuple
                on_delete_args.should == [[updated_tuple]]
              end

              it "triggers the on_insert event with the new first Tuple in #operand" do
                on_insert_args = []
                singleton_relation.on_insert(retainer) do |*args|
                  on_insert_args.push(args)
                end
                updated_tuple.employee_id = 9999
                operand.tuples.first.should_not == updated_tuple
                on_insert_args.should == [[operand.tuples.first]]
              end

              it "triggers the on_change event with self" do
                on_change_args = []
                singleton_relation.on_change(retainer) do |*args|
                  on_change_args.push(args)
                end
                updated_tuple.employee_id = 9999
                operand.tuples.first.should_not == updated_tuple
                on_change_args.should == [[singleton_relation]]
              end
            end
          end

          context "when the Tuple is not first in the #operand" do
            attr_reader :updated_tuple
            before do
              @updated_tuple = operand.tuples[1]
            end

            context "when the Tuple remains not first in #operand" do
              attr_reader :old_name, :new_name
              before do
                @old_name = singleton_relation.tuple.name
                @new_name = "#{old_name} that is changed"
              end
              
              it "does not change #tuple" do
                lambda do
                  updated_tuple.name = new_name
                end.should_not change {singleton_relation.tuple}
              end              

              it "does not trigger the on_tuple_update event" do
                singleton_relation.on_tuple_update(retainer) do |tuple, attribute, old_value, new_value|
                  raise "Don't taze me"
                end
                updated_tuple.name = new_name
              end

              it "does not trigger the on_delete event" do
                singleton_relation.on_delete(retainer) do |*args|
                  raise "Don't taze me bro"
                end
                updated_tuple.name = new_name
              end

              it "does not trigger the on_insert event" do
                singleton_relation.on_insert(retainer) do |*args|
                  raise "Don't taze me bro"
                end
                updated_tuple.name = new_name
              end

              it "does not trigger the on_change event" do
                singleton_relation.on_change(retainer) do |*args|
                  raise "Don't taze me bro"
                end
                updated_tuple.name = new_name
              end
            end

            context "when the update causes the Tuple to be the first in #operand" do
              it "changes #tuple to be the updated Tuple" do
                updated_tuple.employee_id = 0
                updated_tuple.should == operand.tuples.first
                singleton_relation.tuple.should == updated_tuple
              end

              it "does not trigger the on_tuple_update event" do
                singleton_relation.on_tuple_update(retainer) do |tuple, attribute, old_value, new_value|
                  raise "Don't taze me"
                end
                updated_tuple.employee_id = 0
                updated_tuple.should == operand.tuples.first
              end

              it "triggers the on_delete event with old value of #tuple" do
                old_tuple = singleton_relation.tuple
                on_delete_args = []
                singleton_relation.on_delete(retainer) do |*args|
                  on_delete_args.push(args)
                end
                updated_tuple.employee_id = 0
                updated_tuple.should == operand.tuples.first
                on_delete_args.should == [[old_tuple]]
              end

              it "triggers the on_insert event with the updated Tuple" do
                on_insert_args = []
                singleton_relation.on_insert(retainer) do |*args|
                  on_insert_args.push(args)
                end
                updated_tuple.employee_id = 0
                updated_tuple.should == operand.tuples.first
                on_insert_args.should == [[updated_tuple]]
              end

              it "triggers the on_change event with self" do
                on_change_args = []
                singleton_relation.on_change(retainer) do |*args|
                  on_change_args.push(args)
                end
                updated_tuple.employee_id = 0
                updated_tuple.should == operand.tuples.first
                on_change_args.should == [[singleton_relation]]
              end
            end
          end
        end
      end

      context "when not #retained?" do
        describe "#after_first_retain" do
          attr_reader :retainer
          before do
            @retainer = Object.new
            mock.proxy(singleton_relation).after_first_retain
          end

          after do
            singleton_relation.release_from(retainer)
          end

          it "retains the Tuples inserted by #initial_read" do
            singleton_relation.retain_with(retainer)
            singleton_relation.tuples.should_not be_empty
            singleton_relation.tuples.each do |tuple|
              tuple.should be_retained_by(singleton_relation)
            end
          end
        end


        describe "#tuple" do
          it "returns #operand.tuples.first" do
            operand.should_not be_empty
            singleton_relation.tuple.should == operand.tuples.first
          end
        end

        describe "#tuples" do
          context "when #operand.tuples is empty" do
            def operand
              @operand ||= accounts_set.where(accounts_set[:employee_id].eq(999))
            end

            it "returns []" do
              operand.should be_empty
              singleton_relation.tuples.should == []
            end
          end

          context "when #operand.tuples not empty" do
            it "returns [#operand.tuples.first]" do
              singleton_relation.tuples.should == [operand.tuples.first]
            end
          end
        end
      end
    end
  end
end