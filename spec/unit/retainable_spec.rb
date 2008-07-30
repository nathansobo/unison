require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

module Unison
  describe Retainable do
    attr_reader :retainable
    before do
      @retainable = users_set
    end

    describe "#retain" do
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
  end
end
