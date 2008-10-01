require File.expand_path("#{File.dirname(__FILE__)}/../unison_spec_helper")

module Unison
  describe SyntheticField do
    attr_reader :tuple, :attribute, :field
    before do
      @tuple = User.find("nathan")
      @attribute = User[:conqueror_name]
      @field = SyntheticField.new(tuple, attribute)
    end

    describe "#value" do
      it "delegates to the result of #signal" do
        expected_value = field.signal.value
        mock.proxy(field.signal).value
        field.value.should == expected_value
      end
    end

    describe "#signal" do
      it "returns the result of instance evaling the #attribute's #definition block in #tuple" do
        expected_signal = tuple.instance_eval(&attribute.definition)
        field.signal.value.should == expected_signal.value 
      end

      it "memoizes its result" do
        signal = field.signal
        field.signal.should equal(signal)
      end
    end

    describe "#==" do
      context "when passed a SyntheticField with the same #attribute" do
        it "returns true" do
          other = SyntheticField.new(field.tuple, field.attribute)
          field.should == other
        end
      end

      context "when passed a SyntheticField with a different #attribute" do
        it "returns false" do
          other = SyntheticField.new(field.tuple, User[:id])
          other.attribute.should_not == field.attribute
          field.should_not == other
        end
      end

      context "when passed an Object that is not an instance of SyntheticField" do
        it "returns false" do
          field.should_not == Object.new
        end
      end
    end
  end
end
