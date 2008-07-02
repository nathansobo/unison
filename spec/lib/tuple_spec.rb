require "#{File.dirname(__FILE__)}/../spec_helper"

module Unison
  describe Tuple::Base do
    attr_reader :tuple_class, :tuple
    before do
      @tuple_class = users_set.tuple_class
      tuple_class.superclass.should == Tuple::Base
      @tuple = tuple_class.new(:id => 1, :name => "Nathan")
    end

    describe "#initialize" do
      it "assigns a hash of attribute-value pairs corresponding to its relation" do
        tuple = tuple_class.new(:id => 1, :name => "Nathan")
        tuple[:id].should == 1
        tuple[:name].should == "Nathan"
      end
    end

    describe "#[]" do
      it "retrieves the value for an Attribute defined on the relation of the Tuple class" do
        tuple[tuple_class.relation[:id]].should == 1
        tuple[tuple_class.relation[:name]].should == "Nathan"
      end

      it "retrieves the value for a Symbol corresponding to a name of an Attribute defined on the relation of the Tuple class" do
        tuple[:id].should == 1
        tuple[:name].should == "Nathan"
      end
    end

    describe "#[]=" do
      it "sets the value for an Attribute defined on the relation of the Tuple class" do
        tuple[tuple_class.relation[:id]] = 2
        tuple[tuple_class.relation[:id]].should == 2
        tuple[tuple_class.relation[:name]] = "Corey"
        tuple[tuple_class.relation[:name]].should == "Corey"
      end

      it "sets the value for a Symbol corresponding to a name of an Attribute defined on the relation of the Tuple class" do
        tuple[:id] = 2
        tuple[:id].should == 2
        tuple[:name] = "Corey"
        tuple[:name].should == "Corey"
      end
    end

    describe "#relation" do
      it "delegates to the .relation" do
        tuple.relation.should == tuple_class.relation
      end
    end
  end
end