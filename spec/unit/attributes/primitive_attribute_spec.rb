require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Attributes
    describe PrimitiveAttribute do
      attr_reader :set, :tuple, :attribute, :transform
      before do
        @set = Relations::Set.new(:users)
        @transform = lambda {|value| value}
        set.attributes[attribute.name] = attribute
        @tuple = User.create(:id => "bob", :name => "Bobby")
      end

      def attribute
        @attribute ||= PrimitiveAttribute.new(set, :name, :string, &transform)
      end

      describe "#initialize" do
        it "sets the #set, #name, and #transform" do
          attribute.set.should == set
          attribute.name.should == :name
          attribute.transform.should == transform
        end

        context "when passed an 'invalid' type" do
          it "raises an ArgumentError" do
            lambda do
              PrimitiveAttribute.new(set, :id, :invalid)
            end.should raise_error(ArgumentError)
          end
        end

        context "when name == :id" do
          context "when passed a :default option" do
            def attribute
              @attribute ||= PrimitiveAttribute.new(set, :id, :string, :default => "Hello")
            end

            it "sets the #default to the converted value of the passed in option" do
              attribute.default.should == "Hello"
            end

            context "when :default is false" do
              def attribute
                @attribute ||= PrimitiveAttribute.new(set, :is_awesome, :boolean, :default => false)
              end

              it "sets #default to false" do
                attribute.default.should == false
              end
            end
          end

          context "when not passed a :default option" do
            def attribute
              @attribute ||= PrimitiveAttribute.new(set, :id, :string)
            end

            it "sets the #default to a Proc generating a Guid string" do
              new_guid = nil
              mock.proxy(Guid).new do |guid|
                new_guid = guid
              end
              attribute.default.call.should == new_guid.to_s
            end
          end
        end

        context "when name != :id" do
          context "when passed a :default option" do
            def attribute
              @attribute ||= PrimitiveAttribute.new(set, :name, :string, :default => 999, &transform)
            end

            it "sets the #default to the converted value of the passed in option" do
              attribute.default.should == 999
            end

            context "when name == :id" do
              def attribute
                @attribute ||= PrimitiveAttribute.new(set, :id, :string, :default => "Hello")
              end

              it "sets the #default to the converted value of the passed in option" do
                attribute.default.should == "Hello"
              end

              context "when :default is false" do
                def attribute
                  @attribute ||= PrimitiveAttribute.new(set, :is_awesome, :boolean, :default => false)
                end

                it "sets #default to false" do
                  attribute.default.should == false
                end
              end
            end
          end

          context "when not passed a :default option" do
            it "sets #default to nil" do
              attribute.default.should be_nil
            end
          end
        end
      end

      class << self
        define_method "when passed nil, returns nil" do
          it "when passed nil, returns nil" do
            attribute.convert(nil).should == nil
          end
        end
      end      

      describe "#convert" do
        context "when #type is :integer" do
          before do
            @attribute = PrimitiveAttribute.new(set, :id, :integer)
          end

          send("when passed nil, returns nil")

          it "when passed an Integer, returns the Integer" do
            attribute.convert(5).should == 5
          end

          it "when passed a String of an Integer, returns the Integer representation" do
            attribute.convert("66").should == 66
          end

          it "when passed a String that does not represent an Integer, raises an ArgumentError" do
            lambda do
              attribute.convert("boo")
            end.should raise_error(ArgumentError)
          end
        end

        context "when #type is :string" do
          before do
            @attribute = PrimitiveAttribute.new(set, :name, :string)
          end

          send("when passed nil, returns nil")

          it "when passed a String, returns the String" do
            attribute.convert("hello").should == "hello"
          end

          it "when passed an Object, returns the String representation of the Object" do
            object = Object.new
            attribute.convert(object).should == object.to_s
          end
        end

        context "when #type is :symbol" do
          before do
            @attribute = PrimitiveAttribute.new(set, :state, :symbol)
          end

          send("when passed nil, returns nil")

          it "when passed a Symbol, returns the Symbol" do
            attribute.convert(:hello).should == :hello
          end

          it "when passed an Object, returns the Symbol representation of the Object" do
            object = Object.new
            attribute.convert(object).should == object.to_s.to_sym
          end
        end

        context "when #type is :boolean" do
          before do
            @attribute = PrimitiveAttribute.new(set, :is_cool, :boolean)
          end

          send("when passed nil, returns nil")

          it "when passed true or false, returns identity" do
            attribute.convert(true).should == true
            attribute.convert(false).should == false
          end

          it "when passed 'true', returns true" do
            attribute.convert('true').should == true
          end

          it "when passed 'false', returns false" do
            attribute.convert('false').should == false
          end

          it "when passed nil, returns nil" do
            attribute.convert(nil).should == nil
          end

          it "when passed another value, raises an ArgumentError" do
            lambda do
              attribute.convert(22)
            end.should raise_error(ArgumentError)
          end
        end

        context "when #type is :datetime" do
          before do
            @attribute = PrimitiveAttribute.new(set, :created_at, :datetime)
          end

          send("when passed nil, returns nil")

          it "when passed a Time, returns the time" do
            now = Time.now.utc
            attribute.convert(now).should == now
          end

          it "when passed a String, returns a Time represented by the String, coerced to UTC" do
            attribute.convert("2/4/1999").should == Time.utc(1999, 2, 4)
          end

          it "when passed an Integer, returns a Time represented by the Integer" do
            now = Time.now
            attribute.convert(now.to_i).should == Time.at(now.to_i).utc
          end
        end

        context "when #type is :object" do
          before do
            @attribute = PrimitiveAttribute.new(set, :my_custom_object, :object)
          end

          send("when passed nil, returns nil")

          it "returns the passed-in argument" do
            object = Object.new
            attribute.convert(object).should equal(object)
          end
        end
      end

      describe "#==" do
        it "returns true for Attributes of the same #set, #name, and #transform and returns false otherwise" do
          attribute.should == PrimitiveAttribute.new(set, :name, :string, &transform)
          attribute.should_not == PrimitiveAttribute.new(Relations::Set.new(:foo), :name, :string)
          attribute.should_not == PrimitiveAttribute.new(set, :foo, :string)
          attribute.should_not == PrimitiveAttribute.new(set, :name, :string) {}
          attribute.should_not == Object.new
        end
      end

      describe "#field" do
        it "returns a Field instance with the passed-in #tuple and self set to #attribute" do
          field = attribute.field(tuple)
          field.class.should == Field
          field.tuple.should == tuple
          field.attribute.should == attribute
        end
      end

      describe "predicate constructors" do
        describe "#eq" do
          it "returns an instance of Predicates::EqualTo with the attribute and the argument as its operands" do
            predicate = attribute.eq(1)
            predicate.should be_an_instance_of(Predicates::EqualTo)
            predicate.operand_1.should == attribute
            predicate.operand_2.should == 1
          end
        end

        describe "#neq" do
          it "returns an instance of Predicates::EqualTo with the attribute and the argument as its operands" do
            predicate = attribute.neq(1)
            predicate.should be_an_instance_of(Predicates::NotEqualTo)
            predicate.operand_1.should == attribute
            predicate.operand_2.should == 1
          end
        end

        describe "#gt" do
          it "returns an instance of Predicates::GreaterThan with the attribute and the argument as its operands" do
            predicate = attribute.gt(1)
            predicate.should be_an_instance_of(Predicates::GreaterThan)
            predicate.operand_1.should == attribute
            predicate.operand_2.should == 1
          end
        end

        describe "#lt" do
          it "returns an instance of Predicates::GreaterThan with the attribute and the argument as its operands" do
            predicate = attribute.lt(1)
            predicate.should be_an_instance_of(Predicates::LessThan)
            predicate.operand_1.should == attribute
            predicate.operand_2.should == 1
          end
        end

        describe "#gteq" do
          it "returns an instance of Predicates::GreaterThan with the attribute and the argument as its operands" do
            predicate = attribute.gteq(1)
            predicate.should be_an_instance_of(Predicates::GreaterThanOrEqualTo)
            predicate.operand_1.should == attribute
            predicate.operand_2.should == 1
          end
        end

        describe "#lteq" do
          it "returns an instance of Predicates::GreaterThan with the attribute and the argument as its operands" do
            predicate = attribute.lteq(1)
            predicate.should be_an_instance_of(Predicates::LessThanOrEqualTo)
            predicate.operand_1.should == attribute
            predicate.operand_2.should == 1
          end
        end
      end

      describe "ordering directions" do
        it "defaults to ascending" do
          attribute.should be_ascending
        end

        describe "#ascending" do
          before do
            attribute.ascending
          end

          it "sets #ascending? to true" do
            attribute.should be_ascending
          end

          it "sets #descending? to false" do
            attribute.should_not be_descending
          end
        end

        describe "#descending" do
          before do
            attribute.descending
          end

          it "sets #descending? to true" do
            attribute.should be_descending
          end

          it "sets #ascending? to false" do
            attribute.should_not be_ascending
          end
        end
      end

      describe "#to_arel" do
        before do
          @set = users_set
          @attribute = PrimitiveAttribute.new(set, :name, :string)
        end

        it "returns the Arel::Attribute with the same #name from #set.to_arel" do
          attribute.to_arel.should == attribute.set.to_arel[attribute.name]
        end

        it "when called repeatedly, returns the same Arel::Attribute instance" do
          attribute.to_arel.object_id.should == attribute.to_arel.object_id
        end
      end
    end    
  end
end

