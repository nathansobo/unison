require File.expand_path("#{File.dirname(__FILE__)}/../unison_spec_helper")

module Unison
  describe Retainable do
    def retainer
      @retainer ||= Object.new
    end

    def anonymous_retainable_object(name=nil)
      Class.new do
        include Retainable
        attr_accessor :name
        def initialize(name)
          @name = name
        end

        def inspect
          name || object_id
        end
      end.new(name)
    end

    def retainable
      @retainable ||= retainable_class.new(child, children, hash_children)
    end

    def retainable_class
      @retainable_class ||= Class.new do
        include Retainable
        attr_reader :child, :children, :hash_children

        retain :child, :children, :hash_children

        def initialize(child, children, hash_children)
          @child, @children, @hash_children = child, children, hash_children
        end

        def inspect
          "retainable"
        end
      end
    end

    def child
      @child ||= anonymous_retainable_object
    end

    def children
      @children ||= [anonymous_retainable_object, anonymous_retainable_object]
    end

    def hash_children
      @hash_children ||= {
        1 => anonymous_retainable_object,
        2 => anonymous_retainable_object
      }
    end

    describe ".retain" do
      def self.should_retain_its_children
        it "causes the objects named by the passed-in names to be retained after the first call to #retain_with" do
          child.should_not be_retained_by(retainable)
          children.each do |child_in_children|
            child_in_children.should_not be_retained_by(retainable)
          end
          hash_children.values.each do |hash_child|
            hash_child.should_not be_retained_by(retainable)
          end

          retainable.retain_with(retainer)

          child.should be_retained_by(retainable)
          children.each do |child_in_children|
            child_in_children.should be_retained_by(retainable)
          end
          hash_children.values.each do |hash_child|
            hash_child.should be_retained_by(retainable)
          end
        end

        it "causes the objects named by the passed-in names to be released after the last call to #release_from" do
          retainable.retain_with(retainer)
          child.should be_retained_by(retainable)
          children.each do |child_in_children|
            child_in_children.should be_retained_by(retainable)
          end
          hash_children.values.each do |hash_child|
            hash_child.should be_retained_by(retainable)
          end

          retainable.release_from(retainer)

          child.should_not be_retained_by(retainable)
          children.each do |child_in_children|
            child_in_children.should_not be_retained_by(retainable)
          end
          hash_children.values.each do |hash_child|
            hash_child.should_not be_retained_by(retainable)
          end
        end
      end

      should_retain_its_children

      context "when .retain is invoked by the superclass" do
        before do
          retainable_subclass = Class.new(retainable_class)
          @retainable = retainable_subclass.new(child, children, hash_children)
        end

        should_retain_its_children
      end
    end

    describe ".subscribe" do
      attr_reader :retainable, :retainable_class, :child, :children
      before do
        @child = anonymous_subscribable_object

        @retainable_class = Class.new do
          include Retainable
          attr_reader :child

          retain :child
          subscribe do
            child.subscription_node.subscribe {}
          end
          subscribe do
            [child.subscription_node.subscribe {}, child.subscription_node.subscribe {}]
          end

          def initialize(child)
            @child = child
          end
        end
        @retainable = retainable_class.new(child)
      end

      def anonymous_subscribable_object
        Class.new do
          include Retainable
          attr_reader :subscription_node

          def initialize
            @subscription_node = SubscriptionNode.new(self)
          end
        end.new
      end

      def self.should_subscribe_to_its_children
        it "causes the first call to #retain_with to create a Subscription based on the given definition" do
          publicize retainable, :subscriptions
          retainable.should_not be_subscribed_to(child.subscription_node)
          lambda do
            retainable.retain_with(retainer)
          end.should change {retainable.subscriptions.length}.by(3)
          retainable.should be_subscribed_to(child.subscription_node)
        end

        it "causes the last call to #release_from call to #destroy the #subscriptions" do
          retainable.retain_with(retainer)
          retainable.should be_subscribed_to(child.subscription_node)

          retainable.release_from(retainer)
          retainable.should_not be_subscribed_to(child.subscription_node)
        end
      end

      should_subscribe_to_its_children

      context "when .subscribe is invoked by the superclass" do
        before do
          retainable_subclass = Class.new(retainable_class)
          @retainable = retainable_subclass.new(child)
        end

        should_subscribe_to_its_children
      end

      context "when the subscription definition returns nil" do
        before do
          retainable_class.class_eval do
            subscribe {nil}
          end
          publicize retainable, :subscriptions
        end

        it "after the first call to #retain_with, does not attempt to track the nil subscription" do
          retainable.retain_with(retainer)
          retainable.subscriptions.should_not include(nil)
        end
      end

      context "when the subscription definition returns an Array containing nil(s)" do
        before do
          retainable_class.class_eval do
            subscribe {[nil, child.subscription_node.subscribe {}, nil]}
          end
          publicize retainable, :subscriptions
        end

        it "after the first call to #retain_with, does not attempt to track the nil subscription" do
          lambda do
            retainable.retain_with(retainer)
          end.should change {retainable.subscriptions.length}.by(4)
          retainable.subscriptions.should_not include(nil)
        end
      end
    end

    describe "#retain_with" do
      it "returns self" do
        retainable.retain_with(Object.new).should == retainable
      end

      it "retains its .names_of_children_to_retain only upon its first invocation" do
        retainable = users_set.where(users_set[:id].eq(1))
        retainable.operand.should_not be_retained_by(retainable)

        mock.proxy(retainable.operand).retain_with(retainable)
        retainable.retain_with(Object.new)
        retainable.operand.should be_retained_by(retainable)

        dont_allow(retainable.operand).retain_with(retainable)
        retainable.retain_with(Object.new)
      end

      it "invokes #after_first_retain only after first invocation" do
        retainable = Relations::Set.new(:test)
        mock.proxy(retainable).after_first_retain
        retainable.retain_with(Object.new)

        dont_allow(retainable).after_first_retain
        retainable.retain_with(Object.new)
      end

      context "when passing in a retainer for the first time" do
        it "increments #refcount by 1" do
          lambda do
            retainable.retain_with(Object.new)
          end.should change {retainable.refcount}.by(1)
        end

        it "causes #retained_by? to return true for the retainer" do
          retainer = Object.new
          retainable.should_not be_retained_by(retainer)
          retainable.retain_with(retainer)
          retainable.should be_retained_by(retainer)
        end
      end

      context "when passing in a retainer for the second time" do
        it "raises an ArgumentError" do
          retainer = Object.new
          retainable.retain_with(retainer)

          lambda do
            retainable.retain_with(retainer)
          end.should raise_error(ArgumentError)
        end
      end
    end

    describe "#release_from" do
      before do
        retainable.retain_with(retainer)
      end

      it "causes #retained_by?(retainer) to return false" do
        retainable.release_from(retainer)
        retainable.should_not be_retained_by(retainer)
      end

      it "decrements #refcount by 1" do
        lambda do
          retainable.release_from(retainer)
        end.should change {retainable.refcount}.by(-1)
      end

      context "when the last remaining retainer is released" do
        it "calls #after_last_release on self" do
          retainable.refcount.should == 1
          mock.proxy(retainable).after_last_release
          retainable.release_from(retainer)
        end
      end

      context "when the only remaining retainers have self as their only root ancestral retainer" do
        attr_reader :b
        def a
          retainable
        end

        before do
          @b = anonymous_retainable_object("b")
          b.retain_with(a)
          a.retain_with(b)
        end

        it "calls #after_last_release on self" do
          a.refcount.should == 2
          mock.proxy(retainable).after_last_release
          a.release_from(retainer)
        end
      end

      context "when a remaining retainer has an object other than self as a root ancestral retainer" do
        attr_reader :b, :other_retainer
        def a
          retainable
        end

        def other_retainer
          @other_retainer ||= anonymous_retainable_object
        end

        before do
          @b = anonymous_retainable_object("b")
          a.retain_with(b)
          b.retain_with(other_retainer)
        end

        context "when the remaining retainer's retention graph is acyclic" do
          context "when the remaining retainer's ancestral root mixes in Retainable" do

            before do
              other_retainer.class.ancestors.should include(Retainable)
            end

            it "does not call #after_last_release on self" do
              dont_allow(retainable).after_last_release
              a.release_from(retainer)
            end
          end

          context "when the remaining retainer's ancestral root does not mix in Retainable" do
            def other_retainer
              @other_retainer ||= Object.new
            end

            it "does not call #after_last_release on self" do
              dont_allow(retainable).after_last_release
              a.release_from(retainer)
            end
          end
        end

        context "when the remaining retainer's retention graph is cyclic" do
          context "when the remaining retainer has the object being released as an ancestral retainer, in addition to another ancestral root" do
            before do
              b.retain_with(a)
            end

            it "does not call #after_last_release on self" do
              dont_allow(retainable).after_last_release
              a.release_from(retainer)
            end
          end

          context "when the remaining retainer has cycles in its retention graph that don't involve the object being released" do
            attr_reader :c
            before do
              @c = anonymous_retainable_object("c")
              b.retain_with(c)
              c.retain_with(b)
            end

            it "does not call #after_last_release on self, and does not get stuck in and endless loop" do
              retainable.refcount.should == 2
              dont_allow(retainable).after_last_release
              a.release_from(retainer)
            end
          end
        end
      end
    end

    describe "#retained?" do
      def retainable
        @retainable ||= Relations::Set.new(:test)
      end

      context "when retainable has been retained" do
        before do
          retainable.retain_with(Object.new)
        end

        it "returns true" do
          retainable.should be_retained
        end
      end

      context "when retainable has not been retained" do
        it "returns false" do
          retainable.should_not be_retained
        end
      end
    end

    describe "#subscribed_to?" do
      context "when #subscriptions contains a Subscription that is in the passed in SubscriptionNode" do
        def retainable
          @retainable ||= users_set.where(User[:id].eq(1))
        end

        it "returns true" do
          publicize retainable, :subscriptions
          publicize users_set, :insert_subscription_node

          retainable.retain_with(retainer)
          retainable.subscriptions.should_not be_empty

          retainable.should be_subscribed_to(users_set.insert_subscription_node)
        end
      end
    end
  end
end
