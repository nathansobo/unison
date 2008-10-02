require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

describe Array do
  describe "#has_same_elements_as?" do
    attr_reader :array, :other
    before do
      @array = [1, 2, 3]
    end

    context "when the argument and the receiver have the same elements, but in a different order" do
      before do
        @other = [3, 2, 1]
      end

      it "returns true" do
        array.should have_same_elements_as(other)
      end
    end

    context "when the argument has elements that are not in the receiver" do
      before do
        @other = [3, 2, 1, "YAY"]
      end

      it "returns false" do
        array.should_not have_same_elements_as(other)
      end
    end

    context "when the receiver has elements that are not in the argument" do
      before do
        @other = [3, 2]
      end

      it "returns false" do
        array.should_not have_same_elements_as(other)
      end
    end

    context "when the argument has more occurrences of one element than the receiver" do
      before do
        @other = [3, 2, 1, 1]
      end

      it "returns false" do
        array.should_not have_same_elements_as(other)
      end
    end

    context "when the receiver has more occurrences of one element than the argument" do
      before do
        @other = [3, 2, 1]
        array.push(1)
      end

      it "returns false" do
        array.should_not have_same_elements_as(other)
      end
    end
  end
end