require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module DataObjects
    describe PrimitiveTuple do

      attr_reader :data_object
      before do
        @data_object = PrimitiveTuple.new
      end

      describe "#put" do
        context "when passed a String key" do
          context "and an Integer value" do
            it "puts the name-value pair" do
              data_object.put("foo", 1)
              data_object.get("foo").should == 1
            end
          end

          context "and a String value" do
            it "puts the name-value pair" do
              data_object.put("foo", "bar")
              data_object.get("foo").should == "bar"
            end
          end

          context "and a boolean value" do
            it "puts the name-value pair" do
              data_object.put("foo", false)
              data_object.get("foo").should == false
              data_object.put("foo", true)
              data_object.get("foo").should == true
            end
          end

          context "and a nil value" do
            it "puts the name-value pair" do
              data_object.put("foo", nil)
              data_object.get("foo").should == nil
            end
          end

          context "and a non-Java compatible value" do
            it "raises an ArgumentError" do
              lambda do
                data_object.put("foo", Date.new)
              end.should raise_error(ArgumentError)
            end
          end
        end

        context "when passed a non-String key" do
          it "raises an ArgumentError" do
            lambda do
              data_object.put(1, "bar")
            end.should raise_error(ArgumentError)
          end
        end
      end

      describe "#get" do
        context "when passed a String" do
          context "when a value matches the key" do
            it "returns the value" do
              data_object.put("foo", 1)
              data_object.get("foo").should == 1
            end
          end

          context "when no value matches the key" do
            it "returns nil" do
              data_object.get("foo").should be_nil
            end
          end
        end

        context "when passed a non-String" do
          it "raises an ArgumentError" do
            lambda do
              data_object.get(:foo)
            end.should raise_error(ArgumentError)
          end
        end
      end

      describe "#attributeIterator" do
        describe "the returned iterator" do
          attr_reader :iterator
          before do
            data_object.put("foo", "bar")
            data_object.put("baz", 1)
            @iterator = data_object.attributeIterator
          end

          describe "#hasNext" do
            context "when the iterator is not at the end" do
              it "returns true" do
                iterator.hasNext.should be_true
              end
            end
            context "when the iterator is at the end" do
              it "returns false" do
                iterator.next
                iterator.next
                iterator.hasNext.should be_false                
              end
            end
          end

          describe "#next" do
            context "when the iterator is not at the end" do
              it "advances to the next name-value pair and returns true" do
                iterator.name.should == "foo"
                iterator.next
                iterator.name.should == "baz"
              end
            end

            context "when the iterator is at the end" do
              it "raises an Error" do
                iterator.next
                iterator.next
                lambda do
                  iterator.next
                end.should raise_error
              end
            end
          end

          describe "#name" do
            it "returns the name of the current name-value pair" do
              iterator.name.should == "foo"
              iterator.next
              iterator.name.should == "baz"
            end
          end

          describe "#value" do
            it "returns the value of the current name-value pair" do
              iterator.value.should == "bar"
              iterator.next
              iterator.value.should == 1
            end
          end
        end
      end
    end
  end
end
