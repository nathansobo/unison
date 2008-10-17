require File.expand_path("#{File.dirname(__FILE__)}/../unison_spec_helper")

module Unison
  module RetainableSpec
    describe Retainable do
      attr_reader :child, :array_children, :hash_children
      attr_reader :subscribed_child_1, :subscribed_child_2, :subscribed_child_3
      attr_reader :retainable_instance, :retainer

      class RetainableClass
        include Retainable

        attr_reader :child, :array_children, :hash_children
        attr_reader :subscribed_child_1, :subscribed_child_2, :subscribed_child_3
        retain :child, :array_children, :hash_children
        retain :subscribed_child_1, :subscribed_child_2, :subscribed_child_3

        subscribe do
          subscribed_child_1.subscription_node.subscribe {}
        end

        subscribe do
          [
            subscribed_child_2.subscription_node.subscribe {},
              subscribed_child_3.subscription_node.subscribe {}
          ]
        end

        def initialize(child, array_children, hash_children, subscribed_child_1, subscribed_child_2, subscribed_child_3)
          @child, @array_children, @hash_children = child, array_children, hash_children
          @subscribed_child_1, @subscribed_child_2, @subscribed_child_3 = subscribed_child_1, subscribed_child_2, subscribed_child_3
        end
      end

      class RetainableSubclass < RetainableClass
        attr_reader :subclass_child, :subclass_subscribed_child
        retain :subclass_child

        subscribe do
          subclass_subscribed_child.subscription_node.subscribe {}
        end
        
        def initialize(child, array_children, hash_children, subscribed_child_1, subscribed_child_2, subscribed_child_3, subclass_child, subclass_subscribed_child)
          super(child, array_children, hash_children, subscribed_child_1, subscribed_child_2, subscribed_child_3)
          @subclass_child = subclass_child
          @subclass_subscribed_child = subclass_subscribed_child
        end
      end

      class SimpleRetainableClass
        include Retainable
        attr_reader :name
        def initialize(name=nil)
          @name = name
        end
      end

      def make_retainable_object(name=nil)
        SimpleRetainableClass.new(name)
      end

      class SimpleSubscribableClass < SimpleRetainableClass
        include Retainable
        attr_reader :subscription_node

        def initialize(name=nil)
          super
          @subscription_node = SubscriptionNode.new(self)
        end
      end

      def make_subscribable_object(name=nil)
        SimpleSubscribableClass.new(name)
      end

      before do
        @child = make_retainable_object("child")
        @array_children = [make_retainable_object("array_child_1"), make_retainable_object("array_child_2")]
        @hash_children = {
          1 => make_retainable_object("hash_child_1"),
          2 => make_retainable_object("hash_child_2")
        }

        @subscribed_child_1 = make_subscribable_object("subscribed_child_1")
        @subscribed_child_2 = make_subscribable_object("subscribed_child_2")
        @subscribed_child_3 = make_subscribable_object("subscribed_child_3")

        @retainable_instance = RetainableClass.new(child, array_children, hash_children, subscribed_child_1, subscribed_child_2, subscribed_child_3)
        @retainer = Object.new

        publicize retainable_instance, :children_to_retain, :subscription_definitions
      end

      describe ".retain" do
        it "adds the given Symbols to .names_of_children_to_retain in self" do
          names_of_children_to_retain = RetainableClass.names_of_children_to_retain
          names_of_children_to_retain.should include(:child)
          names_of_children_to_retain.should include(:array_children)
          names_of_children_to_retain.should include(:hash_children)
        end

        it "adds the given Symbols to .names_of_children_to_retain in subclasses" do
          names_of_children_to_retain = RetainableSubclass.names_of_children_to_retain
          names_of_children_to_retain.should include(:child)
          names_of_children_to_retain.should include(:subclass_child)
        end
      end

      describe ".subscribe" do
        it "adds the given Procs to .subscription_definitions in self" do
          RetainableClass.subscription_definitions.length.should == 2
        end
        it "adds the given Procs to .subscription_definitions in subclasses" do
          RetainableSubclass.subscription_definitions.length.should == 3
        end
      end

      describe "#retain_with" do
        after do
          retainable_instance.release_from(retainer)
        end

        it "returns self" do
          retainable_instance.retain_with(retainer).should == retainable_instance
        end

        it "increments the #refcount by 1" do
          lambda do
            retainable_instance.retain_with(retainer)
          end.should change { retainable_instance.refcount }.by(1)
        end

        context "when the receiver is not #retained? when called" do
          before do
            retainable_instance.should_not be_retained
          end

          it "invokes #after_first_retain on self" do
            mock.proxy(retainable_instance).after_first_retain
            retainable_instance.retain_with(retainer)
          end

          it "retains #children_to_retain" do
            retainable_instance.children_to_retain.each do |child|
              child.should_not be_retained_by(retainable_instance)
            end

            retainable_instance.retain_with(retainer)

            retainable_instance.children_to_retain.each do |child|
              child.should be_retained_by(retainable_instance)
            end
          end

          it "adds single Subscriptions returned by executing #subscription_definitons to #subscriptions" do
            retainable_instance.should_not be_subscribed_to(subscribed_child_1.subscription_node)
            retainable_instance.retain_with(retainer)
            retainable_instance.should be_subscribed_to(subscribed_child_1.subscription_node)
          end

          it "adds Arrays of Subscriptions returned by executing #subscription_definitons to #subscriptions" do
            retainable_instance.should_not be_subscribed_to(subscribed_child_2.subscription_node)
            retainable_instance.should_not be_subscribed_to(subscribed_child_3.subscription_node)
            retainable_instance.retain_with(retainer)
            retainable_instance.should be_subscribed_to(subscribed_child_2.subscription_node)
            retainable_instance.should be_subscribed_to(subscribed_child_3.subscription_node)
          end
        end

        context "when the receiver is already #retained? when called" do
          context "when the receiver is not already #retained_by? the argument" do
            attr_reader :second_retainer
            before do
              @second_retainer = Object.new
              retainable_instance.retain_with(second_retainer)
            end

            after do
              retainable_instance.release_from(second_retainer)
            end

            it "does not invoke #after_first_retain on self" do
              dont_allow(retainable_instance).after_first_retain
              retainable_instance.retain_with(retainer)
            end

            it "does not attempt to retain #children_to_retain" do
              retainable_instance.children_to_retain.each do |child|
                dont_allow(child).retain_with(retainable_instance)
              end
              retainable_instance.retain_with(retainer)
            end

            it "does not attempt to execute #subscription_definitons" do
              [subscribed_child_1, subscribed_child_2, subscribed_child_3].each do |child|
                dont_allow(child.subscription_node).subscribe(retainable_instance)
              end
              retainable_instance.retain_with(retainer)
            end
          end

          context "when the receiver is already retained by the argument" do
            before do
              retainable_instance.retain_with(retainer)
            end

            it "raises an ArgumentError" do
              lambda do
                retainable_instance.retain_with(retainer)
              end.should raise_error(ArgumentError)
            end
          end
        end
      end

      describe "#release_from" do
        before do
          retainable_instance.retain_with(retainer)
        end

        it "decrements #refcount by 1" do
          lambda do
            retainable_instance.release_from(retainer)
          end.should change { retainable_instance.refcount }.by(-1)
        end

        def self.should_perform_after_last_release_logic
          it "calls #after_last_release on self" do
            mock.proxy(retainable_instance).after_last_release
            retainable_instance.release_from(retainer)
          end

          it "releases all #children_to_retain" do
            retainable_instance.children_to_retain.each do |child|
              child.should be_retained_by(retainable_instance)
            end

            retainable_instance.release_from(retainer)

            retainable_instance.children_to_retain.each do |child|
              child.should_not be_retained_by(retainable_instance)
            end
          end

          it "destroys all #subscriptions" do
            [subscribed_child_1, subscribed_child_2, subscribed_child_3].each do |child|
              retainable_instance.should be_subscribed_to(child.subscription_node)
            end

            retainable_instance.release_from(retainer)

            [subscribed_child_1, subscribed_child_2, subscribed_child_3].each do |child|
              retainable_instance.should_not be_subscribed_to(child.subscription_node)
            end
          end
        end

        def self.should_not_perform_after_last_release_logic
          it "does not call #after_last_release on self" do
            dont_allow(retainable_instance).after_last_release
            retainable_instance.release_from(retainer)
          end

          it "does not release all #children_to_retain" do
            retainable_instance.children_to_retain.each do |child|
              child.should be_retained_by(retainable_instance)
            end

            retainable_instance.release_from(retainer)

            retainable_instance.children_to_retain.each do |child|
              child.should be_retained_by(retainable_instance)
            end
          end

          it "does not destroys all #subscriptions" do
            [subscribed_child_1, subscribed_child_2, subscribed_child_3].each do |child|
              retainable_instance.should be_subscribed_to(child.subscription_node)
            end

            retainable_instance.release_from(retainer)

            [subscribed_child_1, subscribed_child_2, subscribed_child_3].each do |child|
              retainable_instance.should be_subscribed_to(child.subscription_node)
            end
          end
        end

        context "when the last remaining retainer is released" do
          before do
            retainable_instance.refcount.should == 1
          end

          should_perform_after_last_release_logic
        end

        context "when the only remaining retainers have retention graphs with no terminus other than the receiver" do
          #  retainer ---> a <--- b
          #                |      ^
          #                |------|

          def a
            retainable_instance
          end

          attr_reader :b
          before do
            @b = make_retainable_object

            a.retain_with(b)
            b.retain_with(a)
          end

          should_perform_after_last_release_logic
        end

        context "when a remaining retainer has a retention graph with a terminus other than the receiver" do
          context "when the remaining retainer's retention graph is acyclic" do
            before do
              retainable_instance.retain_with(second_retainer)
            end

            context "when the remaining retainer's terminus mixes in Retainable" do
              def second_retainer
                @second_retainer ||= make_retainable_object
              end

              should_not_perform_after_last_release_logic
            end

            context "when the remaining retainer's ancestral terminus does not mix in Retainable" do
              def second_retainer
                @second_retainer ||= Object.new
              end

              should_not_perform_after_last_release_logic
            end
          end

          context "when the remaining retainer's retention graph is cyclic" do
            context "when the remaining retainer's retention graph has the object being released as one terminus, in addition to another terminus" do
              # retainer ---> a <--- b <--- x
              #               |      |
              #               |------|

              before do

              end

            end

            context "when the remaining retainer's retention graph has cycles that don't involve the object being released" do
              it "does not call #after_last_release on self, and does not get stuck in and endless loop"
            end
          end
        end
      end

      describe "#children_to_retain" do
        it "includes single Retainable objects named by #names_of_children_to_retain"
        it "includes all Retainable elements in Arrays named by #names_of_children_to_retain"
        it "includes all Retainable values in  Hashes named by #names_of_children_to_retain"
      end

      describe "#subscription_definitions" do
        it "delegates to self.class"
      end

      describe "#retained?" do
      context "when retainable has been retained" do
        it "returns true"
      end

      context "when retainable has not been retained" do
        it "returns false"
      end
    end

      describe "#retained_by?" do
        context "when the #retain_with has been called with the argument" do
          it "returns true"
        end
        context "when the #retain_with has not been called with the argument" do
          it "returns false"
        end
      end

      describe "#subscribed_to?" do
        context "when #subscriptions contains a Subscription that is in the passed in SubscriptionNode" do
          it "returns true"
        end
      end
    end
  end
end
