require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Relations
    describe Set do
      attr_reader :set, :retainer
      before do
        @set = Set.new(:users)
        @retainer = Object.new
        set.has_attribute(:id, :string)
        set.has_attribute(:name, :string)
        set.retain_with(retainer)
      end

      describe "#initialize" do
        it "sets the name of the set" do
          set.name.should == :users

        end
        it "sets the #tuple_class of the Set to a subclass of Tuple::Base, and sets its #relation to itself" do
          tuple_class = set.tuple_class
          tuple_class.superclass.should == PrimitiveTuple
          tuple_class.set.should == set
        end
      end

      describe "#has_attribute" do
        context "when an Attribute with the same name has not already been added" do
          it "adds an Attribute to the Set by the given name" do
            set = Set.new(:user)
            set.has_attribute(:name, :string)
            set.attributes.should == {:name => Attribute.new(set, :name, :string)}
          end

          it "returns the Attribute with the block as its #transform" do
            set = Set.new(:user)
            transform = lambda {|value| "#{value} transformed"}
            attribute = set.has_attribute(:name, :string, &transform)
            attribute.should == Attribute.new(set, :name, :string, &transform)
            attribute.transform.should == transform
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

      describe "#has_synthetic_attribute" do
        attr_reader :set, :definition
        before do
          @set = users_set
          @definition = lambda do
            signal(:name).signal(:length)
          end
        end

        context "when an Attribute with the same name has not already been added" do
          it "adds a SyntheticAttribute to the Set by the given name and returns it" do
            attribute = set.has_synthetic_attribute(:name_length, &definition)
            attribute.should == SyntheticAttribute.new(set, :name_length, &definition)
            set.attributes[:name_length].should == attribute
          end
        end

        context "when an Attribute with the same name has already been added" do
          before do
            set.has_synthetic_attribute(:name_length, &definition)
          end

          it "raises an ArgumentError" do
            lambda do
              set.has_synthetic_attribute(:name_length, &definition)
            end.should raise_error(ArgumentError)
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

        it "when passed the Set itself, returns true" do
          set.should have_attribute(set)
        end
      end

      describe "#attribute" do
        it "retrieves the Set's Attribute by the given name" do
          set.attribute(:id).should == Attribute.new(set, :id, :integer)
          set.attribute(:name).should == Attribute.new(set, :name, :string)
        end
        
        context "when no Attribute with the passed-in name is defined" do
          it "raises an ArgumentError" do
            lambda do
              set.attribute(:i_dont_exist)
            end.should raise_error(ArgumentError)
          end
        end
      end

      describe "#compound?" do
        it "returns false" do
          set.should_not be_compound
        end
      end

      describe "#push" do
        it "calls #push with self on the given Repository" do
          mock.proxy(origin).push(set)
          set.push(origin)
        end
      end

      describe "#set" do
        it "returns self" do
          set.set.should == set
        end
      end

      describe "#composed_sets" do
        it "returns [self]" do
          set.composed_sets.should == [set]
        end
      end

      describe "#insert" do
        context "when #retained?" do
          before do
            set.should be_retained
          end

          it "adds the given Tuple to the results of #tuples" do
            tuple = set.tuple_class.new(:id => "nathan", :name => "Nathan")
            lambda do
              set.insert(tuple).should == tuple
            end.should change {set.size}.by(1)
            set.tuples.should include(tuple)
          end

          context "when an Tuple with the same #id exists in the Set" do
            before do
              set.insert(set.tuple_class.new(:id => "nathan"))
            end

            it "raises an ArgumentError" do
              set.find("nathan").should_not be_nil
              lambda do
                set.insert(set.tuple_class.new(:id => "nathan"))
              end.should raise_error(ArgumentError)
            end
          end

          context "when the Tuple is #new?" do
            it "calls #after_create on the PrimitiveTuple before triggering the the on_insert event" do
              call_order = []
              tuple = set.tuple_class.new(:id => "nathan", :name => "Nathan")
              mock.proxy(tuple).after_create do |returns|
                call_order.push(:after_create)
                returns
              end
              set.on_insert(retainer) do |*args|
                call_order.push(:on_insert)
              end

              set.insert(tuple)
              call_order.should == [:after_create, :on_insert]
            end
          end

          context "when the Tuple is not #new?" do
            it "does not call #after_create on the PrimitiveTuple" do
              tuple = set.tuple_class.new(:id => "nathan", :name => "Nathan")
              tuple.pushed
              tuple.should_not be_new
              dont_allow(tuple).after_create
              set.insert(tuple)
            end
          end

          it "when the Set is not the passed in object's #relation, raises an ArgumentError" do
            incorrect_tuple = Profile.find("nathan_profile")
            incorrect_tuple.set.should_not == set

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
              set.insert(set.tuple_class.new(:id => "bob"))
            end.should raise_error
          end
        end
      end

      describe "#delete" do
        context "when the Tuple is in the Set" do
          attr_reader :tuple
          before do
            @tuple = set.tuple_class.create(:id => "nathan", :name => "Nathan")
          end

          it "removes the Tuple from the Set" do
            set.tuples.should include(tuple)
            set.delete(tuple)
            set.tuples.should_not include(tuple)
          end
        end

        context "when the Tuple is not in the Set" do
          attr_reader :tuple_not_in_set
          before do
            @tuple_not_in_set = set.tuple_class.new(:id => "nathan_not_in_set", :name => "Nathan")
            set.tuples.should_not include(tuple_not_in_set)
          end
          
          it "raises an Error" do
            lambda do
              set.delete(tuple_not_in_set)
            end.should raise_error(ArgumentError)
          end
        end
      end

      describe "#on_insert" do
        it "will invoke the block when a Tuple is inserted" do
          inserted = nil
          set.on_insert(retainer) do |tuple|
            inserted = tuple
          end
          tuple = set.tuple_class.new(:id => "nathan", :name => "Nathan")
          set.insert(tuple)
          inserted.should == tuple
        end
      end

      describe "#on_delete" do
        it "will invoke the block when a Tuple is deleted from the Set" do
          tuple = set.tuple_class.create(:id => "nathan", :name => "Nathan")
          deleted = nil
          set.on_delete(retainer) do |deleted_tuple|
            deleted = deleted_tuple
          end

          set.delete(tuple)
          deleted.should == tuple
        end
      end

      describe "#merge" do
        context "when passed some Tuples that have the same id as Tuples already in the Set and some that don't" do
          attr_reader :in_set, :not_in_set, :tuples
          before do
            set.tuple_class.create(:id => "in_set", :name => "Wil")
            @in_set = set.tuple_class.new(:id => "in_set", :name => "Kunal")
            @not_in_set = set.tuple_class.new(:id => "not_in_set", :name => "Nathan")
            set.find(in_set[:id]).should_not be_nil
            set.find(not_in_set[:id]).should be_nil
            @tuples = [in_set, not_in_set]
          end

          it "inserts the Tuples whose id's do not correspond to existing Tuples and does not attempt to insert others" do
            mock.proxy(set).insert(not_in_set)
            dont_allow(set).insert(in_set)
            set.merge(tuples)
            set.should include(not_in_set)
          end
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
    end
  end
end
