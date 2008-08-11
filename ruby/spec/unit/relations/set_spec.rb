require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

module Unison
  module Relations
    describe Set do
      attr_reader :set
      before do
        @set = Set.new(:users)
        set.has_attribute(:id, :integer)
        set.has_attribute(:name, :string)
        set.retain(Object.new)
      end

      describe "#initialize" do
        it "sets the name of the set" do
          set.name.should == :users

        end
        it "sets the #tuple_class of the Set to a subclass of Tuple::Base, and sets its #relation to itself" do
          tuple_class = set.tuple_class
          tuple_class.superclass.should == PrimitiveTuple::Base
          tuple_class.relation.should == set
        end
      end

      describe "#attribute" do
        context "when an Attribute with the same name has not already been added" do
          it "adds an Attribute to the Set by the given name" do
            set = Set.new(:user)
            set.has_attribute(:name, :string)
            set.attributes.should == {:name => Attribute.new(set, :name, :string)}
          end

          it "returns the Attribute" do
            set = Set.new(:user)
            set.has_attribute(:name, :string).should == Attribute.new(set, :name, :string)
          end
        end

        context "when an Attribute with the same name has already been added" do
          context "when the previously added Attribute has the same #type" do
            attr_reader :set, :attribute
            before do
              @set = Set.new(:user)
              @attribute = set.has_attribute(:name, :string)
            end
            
            it "returns the previously added Attribute" do
              set.has_attribute(:name, :string).should equal(attribute)
            end
          end

          context "when the previously added Attribute has a different #type" do
            attr_reader :set
            before do
              @set = Set.new(:user)
              set.has_attribute(:name, :string)
            end

            it "raises an ArgumentError" do
              lambda do
                set.has_attribute(:name, :symbol)
              end.should raise_error(ArgumentError)
            end
          end
        end
      end

      describe "#has_attribute?" do
        it "when passed an Attribute, returns true if the #attributes contains the argument and false otherwise" do
          set.should have_attribute(Attribute.new(set, :name, :string))
          set.should_not have_attribute(Attribute.new(set, :bogus, :integer))
        end

        it "when passed a Symbol, returns true if the #attributes contains an Attribute with that symbol as its name and false otherwise" do
          set.should have_attribute(:name)
          set.should_not have_attribute(:bogus)
        end
      end

      describe "#[]" do
        it "retrieves the Set's Attribute by the given name" do
          set[:id].should == Attribute.new(set, :id, :integer)
          set[:name].should == Attribute.new(set, :name, :string)
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
        context "when #retained?" do
          before do
            set.should be_retained
          end

          context "when an Tuple with the same #id exists in the Set" do
            it "raises an ArgumentError" do
              set.find(11).should_not be_nil
              lambda do
                set.insert(set.tuple_class.new(:id => 11))
              end.should raise_error(ArgumentError)
            end
          end

          it "adds tuples to the Set and the added tuples" do
            tuple = set.tuple_class.new(:id => 1, :name => "Nathan")
            lambda do
              set.insert(tuple).should == tuple
            end.should change {set.size}.by(1)
            set.read.should include(tuple)
          end

          it "when self is not the passed in object's #relation, raises an ArgumentError" do
            incorrect_tuple = Profile.find(1)
            incorrect_tuple.relation.should_not == set

            lambda do
              set.insert(incorrect_tuple)
            end.should raise_error(ArgumentError)
          end
        end

        context "when not #retained?" do
          before do
            @set = Set.new(:users)
            set.has_attribute(:id, :integer)
            set.should_not be_retained
          end

          it "raises an error" do
            lambda do
              set.insert(set.tuple_class.new(:id => 100))
            end.should raise_error
          end
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
        context "when #retained?" do
          before do
            set.should be_retained
            class << set
              public :tuples
            end
          end

          it "returns all Tuples in the Set" do
            set.insert(set.tuple_class.new(:id => 1, :name => "Nathan"))
            set.insert(set.tuple_class.new(:id => 2, :name => "Alissa"))
            set.read.should == set.tuples
          end
        end

        context "when not #retained?" do
          before do
            @set = Set.new(:users)
            set.should_not be_retained
          end
          
          context "when #attributes is not empty" do
            before do
              set.has_attribute(:id, :integer)
              set.has_attribute(:name, :string)
              set.attributes.should_not be_empty
            end

            it "returns all Tuples from a database query of the table" do
              set.read.should == origin.pull(set)
            end
          end

          context "when #attributes is empty" do
            before do
              set.attributes.should be_empty
            end

            it "raises an error" do
              lambda do
                set.read
              end.should raise_error
            end
          end
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

      describe "#to_sql" do
        it "returns a 'select #attributes from #name'" do
          set.to_sql.should be_like("SELECT `users`.`id`, `users`.`name` FROM `users`")
        end
      end

      describe "#to_arel" do
        it "returns the Arel::Table representation of the instance" do
          set.to_arel.should == Arel::Table.new(set.name, Adapters::Arel::Engine.new(self))
        end

        it "when called many times, returns the same instance" do
          set.to_arel.object_id.should == set.to_arel.object_id
        end

        describe "returned value" do
          it "has the Arel representation of the Set's Attributes" do
            set.attributes.should_not be_empty
            set.to_arel.attributes.should_not be_empty
            set.attributes.length.should == set.to_arel.attributes.length
            set.attributes.each do |attribute_name, attribute|
              set.to_arel[attribute_name].should_not be_nil
            end
          end
        end
      end

      describe "#tuples" do
        context "when #retained?" do
          before do
            @set = Set.new(:users).retain(Object.new)
            set.has_attribute(:id, :integer)
            set.has_attribute(:name, :string)
            set.has_attribute(:hobby, :string)
            class << set
              public :tuples, :initial_read
            end
            set.initial_read.should_not be_empty
          end

          it "#inserts each of the Tuples returned by #initial_read" do
            initial_read = set.initial_read
            initial_read.each do |tuple|
              mock.proxy(set).insert(tuple)
            end
            set.tuples.length.should == initial_read.length
          end
        end

        context "when not #retained?" do
          before do
            @set = Set.new(:users).where(Predicates::Eq.new(true, true))
            set.should_not be_retained
            class << set
              public :tuples
            end
          end

          it "raises an Error" do
            lambda do
              set.tuples
            end.should raise_error
          end
        end
      end
    end
  end
end
