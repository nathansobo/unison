require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Signals
    describe SingletonRelationSignal do
      attr_reader :value, :signal
      before do
        @value = User.where(User[:id].eq("nathan")).singleton
        @signal = SingletonRelationSignal.new(value)
      end

      describe "#initialize" do
        context "when passed a SingletonRelation" do
          it "sets #value to the passed-in SingletonRelation" do
            signal.value.should == value
          end
        end

        context "when not passed a SingletonRelation" do
          it "raises an ArgumentError" do
            lambda do
              SingletonRelationSignal.new(Object.new)
            end.should raise_error(ArgumentError)
          end
        end
      end

      describe "#==" do
        context "when other is an SingletonRelationSignal" do
          context "when other.value == #value" do
            it "returns true" do
              signal.should == SingletonRelationSignal.new(value)
            end
          end

          context "when other.value != value" do
            it "returns true" do
              other_relation = User.where(User[:id].eq("corey")).singleton
              value.should_not == other_relation
              signal.should_not == SingletonRelationSignal.new(other_relation)
            end
          end
        end

        context "when other is not an SingletonRelationSignal" do
          it "returns false" do
            signal.should_not == Object.new
          end
        end
      end

      context "when #retained?" do
        attr_reader :retainer
        before do
          @retainer = Object.new
          signal.retain_with(retainer)
        end

        after do
          signal.release_from(retainer)
        end

        it "retains its #value" do
          value.should be_retained_by(signal)
        end
        
        context "when the #value changes" do
          after do
            value.release_from(retainer)
          end
          
          it "triggers the on_change event" do
            value.retain_with(retainer)

            singleton_on_change_called = false
            value.on_change(retainer) do
              singleton_on_change_called = true
            end
            
            on_change_arguments = []
            signal.on_change(retainer) do |*args|
              on_change_arguments.push(args)
            end

            value.tuple[:name] = "Sobot"
            singleton_on_change_called.should be_true
            on_change_arguments.should == [[value]]
          end
        end
      end
    end
  end
end
