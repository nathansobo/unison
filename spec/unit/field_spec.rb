require File.expand_path("#{File.dirname(__FILE__)}/../unison_spec_helper")

module Unison
  describe Field do
    describe "#set_default_value" do
      attr_reader :tuple, :attribute

      before do
        @tuple = User.find("nathan")
      end

      context "when #attribute has a #default" do
        context "when the #default is not a Proc" do
          before do
            @attribute = User[:hobby]
            attribute.default.should_not be_nil
            attribute.default.class.should_not == Proc
          end

          it "sets #value to the value of #attribute.default" do
            field = Field.new(tuple, attribute)
            field.set_default_value
            field.value.should == attribute.default
          end

          it "does not set #dirty? to true" do
            field = Field.new(tuple, attribute)
            field.set_default_value
            field.should be_dirty
          end
        end

        context "when the #default is a Proc" do
          before do
            @attribute = User.set.add_primitive_attribute(:shoes, :string, :default => lambda {name.length * 2})
            attribute.default.should_not be_nil
            attribute.default.class.should == Proc
          end

          it "sets #value to the converted result of #tuple.instance_eval(&the_passed_in_Proc)" do
            field = Field.new(tuple, attribute)
            field.set_default_value
            field.value.should == (tuple.name.length * 2).to_s
          end

          it "does not set #dirty? to true" do
            field = Field.new(tuple, attribute)
            field.set_default_value
            field.should be_dirty
          end
        end

        context "when the #default is false" do
          before do
            @attribute = User.set.add_primitive_attribute(:is_awesome, :boolean, :default => false)
            attribute.default.should == false
          end

          it "sets #value to the value returned by #attribute.default" do
            field = Field.new(tuple, attribute)
            field.set_default_value
            field.value.should == false
          end
        end
      end

      context "when #attribute does not have a #default" do
        before do
          @attribute = User[:name]
          attribute.default.should be_nil
        end

        it "calls #set_value with #attribute's #default" do
          field = Field.new(tuple, attribute)
          field.set_default_value
          field.value.should be_nil
        end

        it "does not set #dirty? to true" do
          field = Field.new(tuple, attribute)
          field.set_default_value
          field.should_not be_dirty
        end
      end      
    end

    describe "#initialize" do
      attr_reader :tuple, :attribute

      before do
        @tuple = User.find("nathan")
      end
    end

    describe "#set_value" do
      attr_reader :tuple, :attribute, :field
      before do
        @attribute = create_attribute
        @tuple = User.create(:id => "bob", :name => "Bob McGraw")
        @field = tuple.fields[attribute]
      end

      def create_attribute
        User[:name]
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
