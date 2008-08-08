require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

module Unison
  describe Retainable do
    attr_reader :retainable
    before do
      @retainable = users_set
    end

    describe "#retain" do
      it "returns self" do
        retainable.retain(Object.new).should == retainable
      end

      it "retains its .children_to_retain only upon its first invocation" do
        retainable = users_set.where(users_set[:id].eq(1))
        retainable.operand.should_not be_retained_by(retainable)

        mock.proxy(retainable.operand).retain(retainable)
        retainable.retain(Object.new)
        retainable.operand.should be_retained_by(retainable)

        dont_allow(retainable.operand).retain(retainable)
        retainable.retain(Object.new)
      end

      it "invokes #after_first_retain only after first invocation" do
        retainable = Relations::Set.new(:test)
        mock.proxy(retainable).after_first_retain
        retainable.retain(Object.new)

        dont_allow(retainable).after_first_retain
        retainable.retain(Object.new)
      end

      context "when passing in a retainer for the first time" do
        it "increments #refcount by 1" do
          lambda do
            retainable.retain(Object.new)
          end.should change {retainable.refcount}.by(1)
        end

        it "causes #retained_by? to return true for the retainer" do
          retainer = Object.new
          retainable.should_not be_retained_by(retainer)
          retainable.retain(retainer)
          retainable.should be_retained_by(retainer)
        end
      end

      context "when passing in a retainer for the second time" do
        it "raises an ArgumentError" do
          retainer = Object.new
          retainable.retain(retainer)

          lambda do
            retainable.retain(retainer)
          end.should raise_error(ArgumentError)
        end
      end
    end

    describe "#release" do
      attr_reader :retainer
      before do
        @retainer = Object.new
        retainable.retain(retainer)
        retainable.should be_retained_by(retainer)
      end

      it "causes #retained_by(retainer) to return false" do
        retainable.release(retainer)
        retainable.should_not be_retained_by(retainer)
      end

      it "decrements #refcount by 1" do
        lambda do
          retainable.release(retainer)
        end.should change {retainable.refcount}.by(-1)
      end

      context "when #refcount becomes > 0" do
        it "does not call #destroy on itself" do
          retainable.retain(Object.new)
          retainable.refcount.should be > 1
          dont_allow(retainable).destroy
          retainable.release(retainer)
        end
      end

      context "when #refcount becomes 0" do
        before do
          @retainable = users_set.where(users_set[:id].eq(1))
          retainable.retain(retainer)
          retainable.refcount.should == 1
        end

        it "calls #destroy on itself" do
          mock.proxy(retainable).destroy
          retainable.release(retainer)
        end
      end
    end

    describe "#retained?" do
      before do
        @retainable = Relations::Set.new(:test)
      end

      context "when retainable has been retained" do
        before do
          retainable.retain(Object.new)
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
  end
end
