require File.expand_path("#{File.dirname(__FILE__)}/../unison_spec_helper")

module Unison
  describe Field do
    describe "#set_value" do
      attr_reader :tuple, :attribute, :field
      before do
        @tuple = User.find("nathan")
        @attribute = User[:name]
        @field = tuple.fields[attribute]
      end
      
      context "when the passed in value is different than the original value" do
        attr_reader :new_value
        before do
          @new_value = "Corey"
          field.value.should_not == new_value
        end
        
        it "sets the #value" do
          field.set_value(new_value)
          field.value.should == new_value
        end

        it "converts the passed in value using the Attribute" do
          mock.proxy(attribute).convert(111)

          field.set_value(111)
          field.value.should == "111"
        end

        context "when not dirty?" do
          before do
            tuple.pushed
            tuple.should_not be_dirty
          end

          it "sets dirty? to true" do
            field.set_value(new_value)
            tuple.should be_dirty
          end
        end        
      end

      context "when the passed in value is the same than the original value" do
        it "does not set #dirty? to true" do
          field.pushed
          field.should_not be_dirty
          field.set_value(field.value)
          field.should_not be_dirty
        end
      end
    end
  end
end
