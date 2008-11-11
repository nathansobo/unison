require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Relations
    describe Set do
      attr_reader :set, :retainer
      before do
        @set = Set.new(:users)
        @retainer = Object.new
        set.add_primitive_attribute(:id, :string)
        set.add_primitive_attribute(:name, :string)
        set.retain_with(retainer)
      end

      after do
        set.release_from(retainer)
      end

      describe ".clear_all" do
        it "calls #clear on every instance of Set" do
          users_set.should_not be_empty
          cameras_set.should_not be_empty
          Set.clear_all
          users_set.should be_empty
          cameras_set.should be_empty
        end
      end

      describe ".load_all_fixtures" do
        it "calls #load_memory_fixtures and #load_database_fixtures on every instance of Set" do
          publicize Set, :instances
          Set.instances.should_not be_empty
          Set.instances.each do |instance|
            mock.proxy(instance).load_memory_fixtures
            mock.proxy(instance).load_database_fixtures
          end
          Set.load_all_fixtures
        end
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

        it "sets #after_create_enabled? to true" do
          set.after_create_enabled?.should be_true
        end

        it "sets #after_merge_enabled? to true" do
          set.after_merge_enabled?.should be_true
        end
      end

      describe "#add_primitive_attribute" do
        context "when an PrimitiveAttribute with the same name has not already been added" do
          it "adds a PrimitiveAttribute to the Set by the given name" do
            set = Set.new(:user)
            set.add_primitive_attribute(:name, :string)
            set.attributes.should == {:name => Attributes::PrimitiveAttribute.new(set, :name, :string)}
          end

          it "returns the PrimitiveAttribute with the block as its #transform" do
            set = Set.new(:user)
            transform = lambda {|value| "#{value} transformed"}
            attribute = set.add_primitive_attribute(:name, :string, &transform)
            attribute.should == Attributes::PrimitiveAttribute.new(set, :name, :string, &transform)
            attribute.transform.should == transform
          end
        end

        describe "#new_tuple" do
          it "returns a new instance of #tuple_class" do
            users_set.new_tuple(:name => 'Jan').class.should == User
          end
        end

        context "when an Attribute with the same name has already been added" do
          context "when the previously added Attribute has the same #type" do
            attr_reader :set, :attribute
            before do
              @set = Set.new(:user)
              @attribute = set.add_primitive_attribute(:name, :string)
            end

            it "returns the previously added Attribute" do
              set.add_primitive_attribute(:name, :string).should equal(attribute)
            end
          end

          context "when the previously added Attribute has a different #type" do
            attr_reader :set
            before do
              @set = Set.new(:user)
              set.add_primitive_attribute(:name, :string)
            end

            it "raises an ArgumentError" do
              lambda do
                set.add_primitive_attribute(:name, :symbol)
              end.should raise_error(ArgumentError)
            end
          end
        end
      end

      describe "#add_synthetic_attribute" do
        attr_reader :set, :definition
        before do
          @set = users_set
          @definition = lambda do
            signal(:name).signal(:length)
          end
        end

        context "when an Attribute with the same name has not already been added" do
          it "adds a SyntheticAttribute to the Set by the given name and returns it" do
            attribute = set.add_synthetic_attribute(:name_length, &definition)
            attribute.should == Attributes::SyntheticAttribute.new(set, :name_length, &definition)
            set.attributes[:name_length].should == attribute
          end
        end

        context "when an Attribute with the same name has already been added" do
          before do
            set.add_synthetic_attribute(:name_length, &definition)
          end

          it "raises an ArgumentError" do
            lambda do
              set.add_synthetic_attribute(:name_length, &definition)
            end.should raise_error(ArgumentError)
          end
        end
      end

      describe "#has_attribute?" do
        before do
          @set = users_set
        end

        it "when passed an Attribute, returns true if the #attributes contains the argument and false otherwise" do
          set.should have_attribute(set[:name])
          set.should_not have_attribute(Attributes::PrimitiveAttribute.new(set, :bogus, :integer))

          set.should have_attribute(set[:conqueror_name])
          set.should_not have_attribute(Attributes::SyntheticAttribute.new(set, :bogus_name) {})
        end

        it "when passed a Symbol, returns true if the #attributes contains an Attribute with that symbol as its name and false otherwise" do
          set.should have_attribute(:name)
          set.should_not have_attribute(:bogus)
        end

        it "when passed the Set itself, returns true" do
          set.should have_attribute(set)
        end
      end

      describe "#add_synthetic_attribute?" do
        before do
          @set = users_set
        end

        context "when passed a SyntheticAttribute" do
          it "returns true if the #attributes contains the argument and false otherwise" do
            set.should have_synthetic_attribute(set[:conqueror_name])
            set.should_not have_synthetic_attribute(Attributes::SyntheticAttribute.new(set, :name_length) { signal(:name).signal(:length)})
          end
        end

        context "when passed a Symbol" do
          it "returns true if the #attributes contains an Attribute with that symbol as its name and false otherwise" do
            set.should have_synthetic_attribute(:conqueror_name)
            set.should_not have_synthetic_attribute(:bogus)
          end
        end

        context "when passed an Attribute" do
          it "returns false" do
            set.should_not have_synthetic_attribute(set[:id])
          end
        end

        context "when passed an object that is not a SyntheticAttribute or Symbol" do
          it "raises an ArgumentError" do
            lambda do
              set.has_synthetic_attribute?(Object.new)
            end.should raise_error(ArgumentError)
          end
        end
      end

      describe "#attribute" do
        it "retrieves the Set's Attribute by the given name" do
          set.attribute(:id).should == Attributes::PrimitiveAttribute.new(set, :id, :integer)
          set.attribute(:name).should == Attributes::PrimitiveAttribute.new(set, :name, :string)
        end
        
        context "when no Attribute with the passed-in name is defined" do
          it "raises an ArgumentError" do
            lambda do
              set.attribute(:i_dont_exist)
            end.should raise_error(ArgumentError)
          end
        end
      end

      describe "#primitive_attributes" do
        attr_reader :synthetic_attribute, :attribute_2
        before do
          @synthetic_attribute = set.add_synthetic_attribute(:name_length) do
            signal(:name).signal(:length)
          end
        end

        it "returns an array of all SyntheticAttributes in #attributes" do
          set.primitive_attributes.should == (set.attributes.values - [synthetic_attribute])
        end
      end

      describe "#synthetic_attributes" do
        attr_reader :attribute_1, :attribute_2
        before do
          @attribute_1 = set.add_synthetic_attribute(:name_length) do
            signal(:name).signal(:length)
          end
          @attribute_2 = set.add_synthetic_attribute(:name_length_times_2) do
            signal(:name).signal(:length) do |length|
              length * 2
            end
          end
        end

        it "returns an array of all SyntheticAttributes in #attributes" do
          set.synthetic_attributes.should == [attribute_1, attribute_2]
        end
      end

      describe "#composite?" do
        it "returns false" do
          set.should_not be_composite
        end
      end

      describe "#push" do
        it "calls #push with self on the given Repository" do
          mock.proxy(origin).push(set)
          set.push
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

      describe "#enable_after_create" do
        it "sets #after_create_enabled? to true" do
          set.disable_after_create
          set.after_create_enabled?.should be_false
          set.enable_after_create
          set.after_create_enabled?.should be_true
        end
      end

      describe "#disable_after_create" do
        it "sets #after_create_enable? to false" do
          set.after_create_enabled?.should be_true
          set.disable_after_create
          set.after_create_enabled?.should be_false
        end
      end

      describe "#enable_after_merge" do
        it "sets #after_merge_enabled? to true" do
          set.disable_after_merge
          set.after_merge_enabled?.should be_false
          set.enable_after_merge
          set.after_merge_enabled?.should be_true
        end
      end

      describe "#disable_after_merge" do
        it "sets #after_merge_enable? to false" do
          set.after_merge_enabled?.should be_true
          set.disable_after_merge
          set.after_merge_enabled?.should be_false
        end
      end

      describe "#insert" do
        context "when #retained?" do
          before do
            set.should be_retained
          end

          it "adds the given Tuple to the results of #tuples" do
            tuple = set.new_tuple(:id => "nathan", :name => "Nathan")
            lambda do
              set.insert(tuple).should == tuple
            end.should change {set.size}.by(1)
            set.tuples.should include(tuple)
          end

          context "when an Tuple with the same #id exists in the Set" do
            before do
              set.insert(set.new_tuple(:id => "nathan"))
            end

            it "raises an ArgumentError" do
              set.find("nathan").should_not be_nil
              lambda do
                set.insert(set.new_tuple(:id => "nathan"))
              end.should raise_error(ArgumentError)
            end
          end

          context "when the Tuple is #new?" do

            context "when after_create is enabled" do
              before do
                set.after_create_enabled?.should be_true
              end

              it "calls #after_create on the PrimitiveTuple before triggering the the on_insert event" do
                call_order = []
                tuple = set.new_tuple(:id => "nathan", :name => "Nathan")
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

            context "when after_create is disabled" do
              before do
                set.disable_after_create
              end

              it "does not call #after_create on the PrimitiveTuple" do
                call_order = []
                tuple = set.new_tuple(:id => "nathan", :name => "Nathan")
                dont_allow(tuple).after_create
                set.insert(tuple)
              end
            end
          end

          context "when the Tuple is not #new?" do
            it "does not call #after_create on the PrimitiveTuple" do
              tuple = set.new_tuple(:id => "nathan", :name => "Nathan")
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
            set.add_primitive_attribute(:id, :integer)
            set.should_not be_retained
          end

          it "raises an error" do
            lambda do
              set.insert(set.new_tuple(:id => "bob"))
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
            @tuple_not_in_set = set.new_tuple(:id => "nathan_not_in_set", :name => "Nathan")
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
          tuple = set.new_tuple(:id => "nathan", :name => "Nathan")
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
            @in_set = set.new_tuple(:id => "in_set", :name => "Kunal")
            @not_in_set = set.new_tuple(:id => "not_in_set", :name => "Nathan")
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

          context "when #after_merge_enabled? is true" do
            before do
              set.after_merge_enabled?.should be_true
            end

            it "calls #after_merge on inserted Tuples" do
              mock.proxy(not_in_set).after_merge
              dont_allow(in_set).after_merge
              set.merge(tuples)
            end
          end

          context "when #after_merge_enabled? is false" do
            before do
              set.disable_after_merge
            end

            it "does not call #after_merge on inserted Tuples" do
              dont_allow(not_in_set).after_merge
              dont_allow(in_set).after_merge
              set.merge(tuples)
            end
          end
        end
      end

      describe "#clear" do
        attr_reader :retainer
        before do
          @retainer = Object.new
          users_set.retain_with(retainer)
        end

        after do
          users_set.release_from(retainer)
        end

        it "deletes all #tuples in the Set" do
          expected_deleted_tuples = users_set.tuples.dup
          deleted_tuples = []
          users_set.on_delete(retainer) do |deleted|
            deleted_tuples.push(deleted)
          end

          users_set.should_not be_empty
          users_set.clear
          users_set.should be_empty
          
          deleted_tuples.should have_same_elements_as(expected_deleted_tuples)
        end
      end

      describe "fixture declaration and loading" do
        attr_reader :fixtures_hash_1, :fixtures_hash_2
        before do
          @fixtures_hash_1 = {
            :bob => {:name => "Bob", :hobby => "Bein' a big boy"},
            :jane => {:name => "Jane", :hobby => "Posing on anti-aircraft guns"}
          }
          @fixtures_hash_2 = {
            :mary => {:name => "Mary", :hobby => "Celery and tomato juice"}
          }
        end

        describe "#memory_fixtures" do
          it "#merges the given hash of fixtures with the existing #declared_memory_fixtures" do
            users_set.declared_memory_fixtures.should == {}
            users_set.memory_fixtures(fixtures_hash_1)
            users_set.declared_memory_fixtures.should == fixtures_hash_1
            users_set.memory_fixtures(fixtures_hash_2)
            users_set.declared_memory_fixtures.should == fixtures_hash_1.merge(fixtures_hash_2)
          end
        end

        describe "#load_memory_fixtures" do
          it "instantiates an instance of #tuple_class for each fixture identified in #declared_memory_fixtures, and inserts it into the Set without #after_create being called" do
            users_set.memory_fixtures(fixtures_hash_1)
            fixtures_hash_1.keys.each do |id|
              users_set.find(id).should be_nil
            end

            users_set.load_memory_fixtures

            fixtures_hash_1.each do |id, attributes|
              fixture = users_set.find(id)
              fixture.after_create_called?.should be_false
              attributes.each do |name, value|
                fixture[name].should == value
              end
            end
          end
        end

        describe "#database_fixtures" do
          it "#merges the given hash of fixtures with the existing #declared_database_fixtures" do
            users_set.declared_database_fixtures.should == {}
            users_set.database_fixtures(fixtures_hash_1)
            users_set.declared_database_fixtures.should == fixtures_hash_1
            users_set.database_fixtures(fixtures_hash_2)
            users_set.declared_database_fixtures.should == fixtures_hash_1.merge(fixtures_hash_2)
          end
        end

        describe "#load_database_fixtures" do
          it "inserts each attributes hash in #declared_database_fixtures into the database table corresponding to the Set" do
            users_set.database_fixtures(fixtures_hash_1)

            fixtures_hash_1.keys.each do |id|
              origin.table_for(users_set).filter(:id => id.to_s).should be_empty
            end

            users_set.load_database_fixtures

            fixtures_hash_1.each do |id, attributes|
              fixture_record = origin.table_for(users_set).filter(:id => id.to_s).first
              attributes.each do |name, value|
                fixture_record[name].should == value
              end
            end
          end
        end
      end

      describe "#fetch_sql" do
        it "returns a 'select #attributes from #name'" do
          set.fetch_sql.should be_like("SELECT `users`.`id`, `users`.`name` FROM `users`")
        end
      end

      describe "#fetch_arel" do
        it "returns the Arel::Table representation of the instance" do
          set.fetch_arel.should == Arel::Table.new(set.name, Adapters::Arel::Engine.new(self))
        end

        it "when called many times, returns the same instance" do
          set.fetch_arel.object_id.should == set.fetch_arel.object_id
        end

        describe "returned value" do
          it "has the Arel representation of the Set's Attributes" do
            set.attributes.should_not be_empty
            set.fetch_arel.attributes.should_not be_empty
            set.attributes.length.should == set.fetch_arel.attributes.length
            set.attributes.each do |attribute_name, attribute|
              set.fetch_arel[attribute_name].should_not be_nil
            end
          end
        end
      end
    end
  end
end
