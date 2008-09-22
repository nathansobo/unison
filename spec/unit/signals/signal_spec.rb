require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Signals
    describe Signal do
      attr_reader :user, :attribute, :signal
      before do
        @user = User.find("nathan")
        @attribute = users_set[:name]
        @signal = user.signal(attribute)
      end

      describe "#to_arel" do
        it "delegates to #value.to_arel" do
          signal.to_arel.should == user[:name].to_arel
        end
      end

      describe "#signal" do
        context "when passed a block" do
          it "returns a DerivedSignal with self as its #source and the given block as its #transform" do
            derived_signal = signal.signal do |value|
              "#{value} the Neurotic"
            end
            derived_signal.class.should == DerivedSignal
            derived_signal.value.should == "Nathan the Neurotic"
          end
        end

        context "when not passed a block" do
          it "raises an ArgumentError" do
            lambda do
              signal.signal
            end.should raise_error(ArgumentError)
          end
        end
      end
    end    
  end
end
