require File.expand_path("#{File.dirname(__FILE__)}/../unison_spec_helper")

module Unison
  describe Attribute do
    attr_reader :set, :attribute
    before do
      @set = Relations::Set.new(:users)
      @attribute = Attribute.new(set, :name, :string)
      set.attributes[attribute.name] = attribute
    end

    describe "#initialize" do
      it "sets the #set and #name" do
        attribute.set.should == set
        attribute.name.should == :name
      end

      context "when passed an 'invalid' type" do
        it "raises an ArgumentError" do
          lambda do
            Attribute.new(set, :id, :invalid)
          end.should raise_error(ArgumentError)
        end
      end
    end

    describe "#convert" do
      context "when #type is :integer" do
        before do
          @attribute = Attribute.new(set, :id, :integer)
        end

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
          @attribute = Attribute.new(set, :name, :string)
        end

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
          @attribute = Attribute.new(set, :state, :symbol)
        end

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
          @attribute = Attribute.new(set, :is_cool, :boolean)
        end
        
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
          @attribute = Attribute.new(set, :created_at, :datetime)
        end

        it "when passed a Time, returns the time" do
          now = Time.now.utc
          attribute.convert(now).should == now
        end

        it "when passed a String, returns a Time represented by the String" do
          attribute.convert("2/4/1999").should == Time.parse("2/4/1999")
        end

        it "when passed an Integer, returns a Time represented by the Integer" do
          now = Time.now
          attribute.convert(now.to_i).should == Time.at(now.to_i)
        end
      end
    end

    describe "#==" do
      it "returns true for Attributes of the same set and name and false otherwise" do
        attribute.should == Attribute.new(set, :name, :string)
        attribute.should_not == Attribute.new(Relations::Set.new(:foo), :name, :string)
        attribute.should_not == Attribute.new(set, :foo, :string)
        attribute.should_not == Object.new
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
        @attribute = Attribute.new(set, :name, :string)
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

