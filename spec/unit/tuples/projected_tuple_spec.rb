require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Tuples
    describe ProjectedTuple do
      attr_reader :base_tuple, :fields, :projected_tuple
      before do
        @base_tuple = User.find("nathan")
        @fields = [base_tuple.field_for(:name), base_tuple.field_for(:hobby)]
        @projected_tuple = ProjectedTuple.new(*fields)
      end

      describe "#[]" do
        context "when passed a Symbol" do
          context "when a Field with the given name was passed to #initialize" do
            it "returns that Field's value" do
              projected_tuple[:name].should == base_tuple[:name]
            end
          end

          context "when a Field with the given name was not passed to #initialize" do
            it "raises an ArgumentError" do
              lambda do
                projected_tuple[:profession]
              end.should raise_error(ArgumentError)
            end
          end
        end

        context "when passed an Attribute" do
          context "when a Field with the given name was passed to #initialize" do
            it "returns that Field's value" do
              projected_tuple[User[:name]].should == base_tuple[:name]
            end
          end

          context "when a Field with the given name was not passed to #initialize" do
            it "raises an ArgumentError" do
              lambda do
                projected_tuple[User[:profession]]
              end.should raise_error(ArgumentError)
            end
          end
        end
      end


      describe "#==" do
        attr_reader :other
        context "when other.fields has the same elements as #fields" do
          before do
            other_base_tuple = User.new(:name => base_tuple.name, :hobby => base_tuple.hobby)
            other_fields = [other_base_tuple.field_for(:name), other_base_tuple.field_for(:hobby)]
            fields.should have_same_elements_as(other_fields)
            @other = ProjectedTuple.new(*other_fields)
          end

          it "returns true" do
            projected_tuple.should == other
          end
        end

        context "when other.fields does not have the same elements as #fields" do
          before do
            other_base_tuple = User.find("corey")
            other_fields = [other_base_tuple.field_for(:name), other_base_tuple.field_for(:hobby)]
            fields.should_not have_same_elements_as(other_fields)
            @other = ProjectedTuple.new(*other_fields)
          end

          it "returns false" do
            projected_tuple.should_not == other
          end
        end

        context "when the argument is not a ProjectedTuple" do
          it "raises an ArgumentError" do
            lambda do
              projected_tuple == Object.new
            end.should raise_error(ArgumentError)
          end
        end
      end
    end
  end
end
