require "#{File.dirname(__FILE__)}/../spec_helper"

module Unison
  describe CompoundTuple::Base do
    attr_reader :nested_tuple_1, :nested_tuple_2, :compound_tuple
    before do
      @nested_tuple_1 = User.new(:id => 1, :name => "Damon")
      @nested_tuple_2 = Photo.new(:id => 1, :name => "Silly Photo", :user_id => 1)
      @compound_tuple = CompoundTuple::Base.new(nested_tuple_1, nested_tuple_2)
    end

    describe "#initialize" do
      it "sets #tuples to an array of the given operands" do
        compound_tuple.tuples.should == [nested_tuple_1, nested_tuple_2]
      end
    end

    describe "#[]" do
      it "retrieves the value of an Attribute from the appropriate nested Tuple" do
        compound_tuple[users_set[:id]].should == nested_tuple_1[users_set[:id]]
        compound_tuple[photos_set[:id]].should == nested_tuple_2[photos_set[:id]]
      end
    end
  end
end
