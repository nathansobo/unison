require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Signals
    describe DerivedSignal do
      attr_reader :tuple, :source_signal, :transform, :derived_signal
      before do
        @tuple = User.find("nathan")
        @source_signal = tuple.signal(:name)
        @transform = lambda do |name|
          "#{name} the Great"
        end
        @derived_signal = DerivedSignal.new(source_signal, &transform)
      end

      describe "#initialize" do
        it "sets #source_signal" do
          derived_signal.source_signal.should == source_signal
        end
      end

      describe "#value" do
        it "returns the result of calling the given tranform on the #value of the #source_signal" do
          derived_signal.value.should == transform.call(source_signal.value)
        end
      end

      context "when #retained?" do
        attr_reader :retainer
        before do
          @retainer = Object.new
          derived_signal.retain_with(retainer)
        end

        it "retains its #source_signal" do
          source_signal.should be_retained_by(derived_signal)
        end

        context "when the #source_signal changes" do
          it "triggers the on_change event with the result of the transform's application to the #value of the #source_signal" do
            new_name = "Ari"
            expected_old_value = transform.call(source_signal.value)
            expected_new_value = transform.call(new_name)

            on_update_arguments = []
            derived_signal.on_change(retainer) do |*args|
              on_update_arguments.push(args)
            end

            tuple.name = new_name
            on_update_arguments.should == [[expected_old_value, expected_new_value]]
          end
        end
      end
    end    
  end
end