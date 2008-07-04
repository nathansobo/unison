require "#{File.dirname(__FILE__)}/../spec_helper"

describe Unison::Tuple::Base do
  attr_reader :tuple_class, :tuple

  describe ".member_of" do
    it "associates the Tuple class with a relation and vice-versa" do
      users_set = User.relation
      users_set.name.should == :users
      users_set.tuple_class.should == User
    end
  end

  describe ".attribute" do
    it "delegates to .relation (BRIAN - This won't work with mock)" do
#      mock(User.relation).attribute(:name)
#      User.attribute(:name)
    end

    it "delegates to .relation" do
      mock.proxy(User.relation).attribute(:name)
      User.attribute(:name)
    end
  end

  describe ".[]" do
    it "delegates to .relation" do
      mock.proxy(User.relation)[:name]
      User[:name]
    end
  end

  describe ".where" do
    it "delegates to .relation" do
      predicate = User[:name].eq("Nathan")
      mock.proxy(User.relation).where(User[:name].eq("Nathan"))
      User.where(User[:name].eq("Nathan"))
    end

  end

  describe ".relates_to_n" do
    it "creates an instance method representing the given relation" do
      user = User.find(1)
      user.photos.should == photos_set.where(photos_set[:user_id].eq(1))
    end
  end

  describe ".find" do
    it "when passed an integer, returns the first Tuple whose :id =='s it" do
      user = User.find(1)
      user.should be_an_instance_of(User)
      user[users_set[:id]].should == 1
    end
  end

  context "instantiated with an attributes hash" do
    before do
      User.superclass.should == Tuple::Base
      @tuple = User.new(:id => 1, :name => "Nathan")
    end

    describe "#initialize" do
      it "assigns a hash of attribute-value pairs corresponding to its relation" do
        tuple = User.new(:id => 1, :name => "Nathan")
        tuple[:id].should == 1
        tuple[:name].should == "Nathan"
      end
    end

    describe "#compound?" do
      it "should be false" do
        tuple.should_not be_compound
      end
    end

    describe "#primitive?" do
      it "should be true" do
        tuple.should be_primitive
      end
    end

    describe "#[]" do
      it "retrieves the value for an Attribute defined on the relation of the Tuple class" do
        tuple[User.relation[:id]].should == 1
        tuple[User.relation[:name]].should == "Nathan"
      end

      it "retrieves the value for a Symbol corresponding to a name of an Attribute defined on the relation of the Tuple class" do
        tuple[:id].should == 1
        tuple[:name].should == "Nathan"
      end
    end

    describe "#[]=" do
      it "sets the value for an Attribute defined on the relation of the Tuple class" do
        tuple[User.relation[:id]] = 2
        tuple[User.relation[:id]].should == 2
        tuple[User.relation[:name]] = "Corey"
        tuple[User.relation[:name]].should == "Corey"
      end

      it "sets the value for a Symbol corresponding to a name of an Attribute defined on the relation of the Tuple class" do
        tuple[:id] = 2
        tuple[:id].should == 2
        tuple[:name] = "Corey"
        tuple[:name].should == "Corey"
      end
    end
  end

  context "instantiated with other tuples" do
    attr_reader :nested_tuple_1, :nested_tuple_2
    before do
      @nested_tuple_1 = User.new(:id => 1, :name => "Damon")
      @nested_tuple_2 = Photo.new(:id => 1, :name => "Silly Photo", :user_id => 1)
      @tuple = Tuple::Base.new(nested_tuple_1, nested_tuple_2)
    end

    describe "#initialize" do
      it "sets #tuples to an array of the given operands" do
        tuple.nested_tuples.should == [nested_tuple_1, nested_tuple_2]
      end
    end

    describe "#compound?" do
      it "should be true" do
        tuple.should be_compound
      end
    end

    describe "#primitive?" do
      it "should be false" do
        tuple.should_not be_primitive
      end
    end

    describe "#[]" do
      it "retrieves the value of an Attribute from the appropriate nested Tuple" do
        tuple[users_set[:id]].should == nested_tuple_1[users_set[:id]]
        tuple[photos_set[:id]].should == nested_tuple_2[photos_set[:id]]
      end
    end
  end
end