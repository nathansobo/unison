require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Tuples
    describe ProjectedTuple do
      attr_reader :base_tuple, :projected_tuple
      before do
        @base_tuple = User.find("nathan")
        @projected_tuple = ProjectedTuple.new(base_tuple.field_for(:id), base_tuple.field_for(:name))
      end

      describe "#[]" do
        context "when passed a Symbol" do
          context "when a Field with the given name was passed to #initialize" do
            it "returns that Field's value" do
              projected_tuple[:id].should == base_tuple[:id]
            end
          end

          context "when a Field with the given name was not passed to #initialize" do
            it "raises an ArgumentError" do
              lambda do
                projected_tuple[:hobby]
              end.should raise_error(ArgumentError)
            end
          end
        end

        context "when passed an Attribute" do
          context "when a Field with the given name was passed to #initialize" do
            it "returns that Field's value" do
              projected_tuple[User[:id]].should == base_tuple[:id]
            end
          end

          context "when a Field with the given name was not passed to #initialize" do
            it "raises an ArgumentError" do
              lambda do
                projected_tuple[User[:hobby]]
              end.should raise_error(ArgumentError)
            end
          end
        end
      end
    end
  end
end
