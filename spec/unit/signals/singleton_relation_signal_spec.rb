require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Signals
    describe SingletonRelationSignal do
      attr_reader :relation, :signal
      before do
        @relation = User.where(User[:id].eq("nathan")).singleton
        @signal = SingletonRelationSignal.new(relation)
      end

      describe "#initialize" do
        context "when passed a SingletonRelation" do
          it "sets #value to the passed-in SingletonRelation" do
            signal.value.should == relation
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
              signal.should == SingletonRelationSignal.new(relation)
            end
          end

          context "when other.value != value" do
            it "returns true" do
              other_relation = User.where(User[:id].eq("corey")).singleton
              relation.should_not == other_relation
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

        it "retains its #value" do
          relation.should be_retained_by(signal)
        end
        
        context "when the #value changes" do
          it "triggers the on_change event" do
            pending "SingletonRelation#on_change" do
              on_update_arguments = []
              signal.on_change(retainer) do |*args|
                on_update_arguments.push(args)
              end

              relation.tuple[:name] = "Sobot"
              on_update_arguments.should == [[signal.value]]
            end
          end
        end
      end
    end
  end
end
