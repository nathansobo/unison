require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Signals
    describe DerivedSignal do
      attr_reader :tuple, :source, :transform, :derived_signal

      before do
        @tuple = User.find("nathan")
        @source = tuple.signal(:name)
      end

      def derived_signal
        @derived_signal ||= DerivedSignal.new(source, &transform)
      end

      def transform
        @transform ||= lambda do |name|
          "#{name} the Great"
        end
      end

      describe "#initialize" do
        it "sets #source" do
          derived_signal.source.should == source
        end
      end

      describe "#value" do
        it "returns the result of calling the given tranform on the #value of the #source" do
          derived_signal.value.should == transform.call(source.value)
        end
      end

      context "when #retained?" do
        attr_reader :retainer
        before do
          @retainer = Object.new
          derived_signal.retain_with(retainer)
        end

        after do
          derived_signal.release_from(retainer)
        end

        it "retains its #source" do
          source.should be_retained_by(derived_signal)
        end

        context "when instantiated with a transform block and not with a Symbol as the second argument" do
          context "when the #source changes" do
            it "triggers the on_change event with the result of #transform.call(#source.value)" do
              new_name = "Ari"
              expected_new_value = transform.call(new_name)
              expected_new_value.should_not == transform.call(source.value)

              on_update_arguments = []
              derived_signal.on_change(retainer) do |*args|
                on_update_arguments.push(args)
              end

              tuple.name = new_name
              on_update_arguments.should == [[expected_new_value]]
            end
          end
        end

        context "when instantiated with a Symbol as the second argument and not a transform block" do
          def derived_signal
            @derived_signal ||= DerivedSignal.new(source, :length)
          end

          context "when the #source changes" do
            it "triggers the on_change event with the result of #source.value.send(#method_name)" do
              new_name = "Ari"
              expected_new_value = new_name.length
              source.value.length.should_not == expected_new_value

              on_update_arguments = []
              derived_signal.on_change(retainer) do |*args|
                on_update_arguments.push(args)
              end

              tuple.name = new_name
              on_update_arguments.should == [[expected_new_value]]
            end
          end
        end

        context "when instantiated with a Symbol as the second argument and a transform block" do
          def derived_signal
            @derived_signal ||= DerivedSignal.new(source, :length, &transform)
          end

          def transform
            @transform ||= lambda do |length|
              "The length of the string is #{length}"
            end
          end

          context "when the #source changes" do
            it "triggers the on_change event with the result of #transform.call(#source.value.send(#method_name))" do
              new_name = "Ari"
              expected_old_value = transform.call(source.value.length)
              expected_new_value = transform.call(new_name.length)
              expected_old_value.should_not == expected_new_value

              on_update_arguments = []
              derived_signal.on_change(retainer) do |*args|
                on_update_arguments.push(args)
              end

              tuple.name = new_name
              on_update_arguments.should == [[expected_new_value]]
            end
          end
        end
        
        context "when not instantiated with a Symbol or a transform block" do
          it "raises an ArgumentError" do
            lambda do
              DerivedSignal.new(source)
            end.should raise_error(ArgumentError)
          end
        end
      end
    end
  end
end