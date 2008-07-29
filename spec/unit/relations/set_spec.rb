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
      end

      describe "#insert" do
        it "adds tuples to the Set and the added tuples" do
          tuple = set.tuple_class.new(:id => 1, :name => "Nathan")
          set.insert(tuple).should == tuple
          set.read.should == [tuple]
        end
      end

      describe "#subscribe" do
        it "for the :insert event type, sends the notifications of the created object to the subscribing Mailbox" do
          mailbox = Mailbox.new
          mailbox.freeze
          users_set.subscribe(mailbox, :insert)
          mailbox.events.should be_empty
          user = User.create(:id => 100, :name => "Farb")
          mailbox.events.length.should == 1
          event = mailbox.events.first
          event.relation.should == users_set
          event.type.should == :insert
          event.object.should == user
        end

        it "will not subscribe to the same event type twice for the same Mailbox" do
          mailbox = Mailbox.new
          mailbox.freeze
          users_set.subscribe(mailbox, :insert)
          users_set.subscribe(mailbox, :insert)
          mailbox.events.should be_empty
          user = User.create(:id => 100, :name => "Farb")
          mailbox.events.length.should == 1
        end
      end

      describe "#read" do
        it "returns all Tuples in the Set" do
          set.insert(set.tuple_class.new(:id => 1, :name => "Nathan"))
          set.insert(set.tuple_class.new(:id => 2, :name => "Alissa"))
          set.read.should == set.tuples
        end
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
