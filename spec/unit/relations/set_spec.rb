require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

module Unison
  module Relations
    describe Set do
      attr_reader :set
      before do
        @set = Set.new(:users)
        set.attribute(:id)
        set.attribute(:name)
      end

      describe "#initialize" do
        it "sets the name of the set" do
          set.name.should == :users

        end
        it "sets the #tuple_class of the Set to a subclass of Tuple::Base, and sets its #relation to itself" do
          tuple_class = set.tuple_class
          tuple_class.superclass.should == Tuple::Base
          tuple_class.relation.should == set
        end
      end

      describe "#attribute" do
        it "adds an Attribute to the Set by the given name" do
          set = Set.new(:user)
          set.attribute(:name)
          set.attributes.should == [Attribute.new(set, :name)]
        end
      end

      describe "#has_attribute?" do
        it "when passed an Attribute, returns true if the #attributes contains the argument and false otherwise" do
          set.should have_attribute(Attribute.new(set, :name))
          set.should_not have_attribute(Attribute.new(set, :bogus))
        end

        it "when passed a Symbol, returns true if the #attributes contains an Attribute with that symbol as its name and false otherwise" do
          set.should have_attribute(:name)
          set.should_not have_attribute(:bogus)
        end
      end

      describe "#[]" do
        it "retrieves the Set's Attribute by the given name" do
          set[:id].should == Attribute.new(set, :id)
          set[:name].should == Attribute.new(set, :name)
        end
        
        context "when no Attribute with the passed-in name is defined" do
          it "raises an ArgumentError" do
            lambda do
              set[:i_dont_exist]
            end.should raise_error(ArgumentError)
          end
        end
      end

      describe "#insert" do
        it "adds tuples to the Set and the added tuples" do
          tuple = set.tuple_class.new(:id => 1, :name => "Nathan")
          set.insert(tuple).should == tuple
          set.read.should == [tuple]
        end
      end

      describe "#delete" do
        context "when the Tuple is in the Set" do
          it "removes the Tuple from the Set" do
            tuple = set.tuple_class.create(:id => 1, :name => "Nathan")

            set.read.should include(tuple)
            set.delete(tuple)
            set.read.should_not include(tuple)
          end
        end

        context "when the Tuple is not in the Set" do
          attr_reader :tuple_not_in_set
          before do
            @tuple_not_in_set = set.tuple_class.new(:id => 100, :name => "Nathan")
            set.read.should_not include(tuple_not_in_set)
          end
          
          it "raises an Error" do
            lambda do
              set.delete(tuple_not_in_set)
            end.should raise_error(ArgumentError)
          end
        end
      end

      describe "#read" do
        it "returns all Tuples in the Set" do
          set.insert(set.tuple_class.new(:id => 1, :name => "Nathan"))
          set.insert(set.tuple_class.new(:id => 2, :name => "Alissa"))
          set.read.should == set.tuples
        end
      end

      describe "#on_insert" do
        it "will invoke the block when a Tuple is inserted" do
          inserted = nil
          set.on_insert do |tuple|
            inserted = tuple
          end
          tuple = set.tuple_class.new(:id => 1, :name => "Nathan")
          set.insert(tuple)
          inserted.should == tuple
        end
      end

      describe "#on_delete" do
        it "will invoke the block when a Tuple is deleted from the Set" do
          tuple = set.tuple_class.create(:id => 1, :name => "Nathan")
          deleted = nil
          set.on_delete do |deleted_tuple|
            deleted = deleted_tuple
          end

          set.delete(tuple)
          deleted.should == tuple
        end

        it "causes the deleted Tuple's instance relations to unsubscribe from their #operands"

      end

      describe "#each" do
        it "iterates over all Tuples in the Set" do
          set.insert(set.tuple_class.new(:id => 1, :name => "Nathan"))
          set.insert(set.tuple_class.new(:id => 2, :name => "Alissa"))

          eached_tuples = []
          set.each do |tuple|
            eached_tuples.push(tuple)
          end
          eached_tuples.should_not be_empty
          eached_tuples.should == set.read
        end
      end
    end
  end
end
