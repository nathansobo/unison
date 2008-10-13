require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Tuples
    describe PrimitiveTuple do
      attr_reader :tuple

      describe "Class Methods" do
        describe ".new" do
          context "when .polymorphic_allocate is overridden" do
            it "returns the object that is returned by .polymorphic_allocate" do
              other_class = Class.new(PrimitiveTuple) do
                member_of(User.set)
              end
              (class << User; self; end).class_eval do
                define_method :polymorphic_allocate do |attrs|
                  other_class.allocate
                end
              end

              instance = User.new
              instance.class.should == other_class
            end
          end
        end

        describe ".member_of" do
          it "associates the Tuple class with a Set and vice-versa" do
            users_set = User.set
            users_set.name.should == :users
            users_set.tuple_class.should == User
          end
        end

        describe ".attribute" do
          it "delegates to .set" do
            mock.proxy(User.set).add_primitive_attribute(:nick_name, :string, {})
            User.attribute(:nick_name, :string)
          end

          context "when passed :default option" do
            it "defaults the PrimitiveAttribute value to the passed-in :default option value" do
              User.attribute_reader(:nick_name, :string, :default => "Bobo")
              User.new.nick_name.should == "Bobo"
            end

            context "when subclassed" do
              it "defaults the PrimitiveAttribute value to the :default option value passed-in to the superclass" do
                User.attribute_reader(:nick_name, :string, :default => "Bobo")
                Developer.new.nick_name.should == "Bobo"
              end
            end
          end

          context "when passed a block" do
            it "causes #[] to return the result of applying the block to the PrimitiveAttribute's value" do
              User.attribute_reader(:nick_name, :string) do |value|
                "homeboy #{value}"
              end
              user = User.new(:nick_name => "Bobo")
              user[:nick_name].should == "homeboy Bobo"
              user.nick_name.should == "homeboy Bobo"
            end
          end
        end

        describe ".attribute_reader" do
          it "creates an attribute on the .set" do
            mock.proxy(User.set).add_primitive_attribute(:nick_name, :string, {})
            User.attribute_reader(:nick_name, :string)
          end

          it "adds a reader method to the Tuple" do
            User.attribute_reader(:nick_name, :string)
            user = User.new(:nick_name => "Bob")
            user.nick_name.should == "Bob"
          end

          it "does not add a writer method to the Tuple" do
            User.attribute_reader(:nick_name, :string)
            user = User.new
            user.should_not respond_to(:nick_name=)
          end

          context "when the type is :boolean" do
            it 'defines a #{name}? reader alias' do
              User.attribute_reader(:has_crabs, :boolean)
              user = User.new(:has_crabs => true)
              user.has_crabs.should be_true
              user.has_crabs?.should be_true
            end
          end

          describe ":default option" do
            context "when a :default is supplied" do
              it "defaults the value to the supplied default value" do
                User.attribute_reader(:nick_name, :string, :default => "jumbo")
                User.new.nick_name.should == "jumbo"
                User.new(:nick_name => "shorty").nick_name.should == "shorty"
              end

              context "when default value is false" do
                it "defaults the attribute value to false" do
                  User.attribute_reader(:is_awesome, :boolean, :default => false)
                  User.new.is_awesome.should be_false
                  User.new(:is_awesome => true).is_awesome.should be_true
                end
              end

              context "when passed a Proc" do
                it "defaults the attribute value to the result of #instance_eval(&the_passed_in_Proc)" do
                  User.attribute_reader(:nick_name, :string, :default => lambda {name + "y"})
                  User.new(:name => "Joe").nick_name.should == "Joey"
                  User.new(:name => "Joe", :nick_name => "Joe Bob").nick_name.should == "Joe Bob"
                  User.new(:name => "Joe", :nick_name => nil).nick_name.should == nil
                end
              end
            end

            context "when a :default is not supplied" do
              it "does not default the value" do
                User.attribute_reader(:nick_name, :string)
                User.new.nick_name.should be_nil
                User.new(:nick_name => "shorty").nick_name.should == "shorty"
              end
            end
          end

        end

        describe ".attribute_writer" do
          it "creates an attribute on the .set" do
            mock.proxy(User.set).add_primitive_attribute(:nick_name, :string, {})
            User.attribute_writer(:nick_name, :string)
          end

          it "adds a writer method to the Tuple" do
            User.attribute_writer(:nick_name, :string)
            user = User.new(:nick_name => "Bob")
            user.nick_name = "Jane"
            user[:nick_name].should == "Jane"
          end

          it "does not add a reader method to the Tuple" do
            User.attribute_writer(:nick_name, :string)
            user = User.new
            user.should_not respond_to(:nick_name)
          end

          describe ":default option" do
            context "when a :default is supplied" do
              it "defaults the value to the supplied default value" do
                User.attribute_writer(:nick_name, :string, :default => "jumbo")
                User.new[:nick_name].should == "jumbo"
                User.new(:nick_name => "shorty")[:nick_name].should == "shorty"
              end

              context "when default value is false" do
                it "defaults the attribute value to false" do
                  User.attribute_reader(:is_awesome, :boolean, :default => false)
                  User.new[:is_awesome].should be_false
                  User.new(:is_awesome => true)[:is_awesome].should be_true
                end
              end
            end

            context "when a :default is not supplied" do
              it "does not default the value" do
                User.attribute_reader(:nick_name, :string)
                User.new[:nick_name].should be_nil
                User.new(:nick_name => "shorty")[:nick_name].should == "shorty"
              end
            end
          end
        end

        describe ".attribute_accessor" do
          it "creates an attribute on the .set" do
            mock.proxy(User.set).add_primitive_attribute(:nick_name, :string, {}).at_least(1)
            User.attribute_accessor(:nick_name, :string)
          end

          it "adds a reader and a writer method to the Tuple" do
            User.attribute_accessor(:nick_name, :string)
            user = User.new(:nick_name => "Bob")
            user.nick_name = "Jane"
            user.nick_name.should == "Jane"
            user[:nick_name].should == "Jane"
          end

          describe ":default option" do
            context "when a :default is supplied" do
              it "defaults the value to the supplied default value" do
                User.attribute_reader(:nick_name, :string, :default => "jumbo")
                User.new.nick_name.should == "jumbo"
                User.new(:nick_name => "shorty").nick_name.should == "shorty"
              end

              context "when default value is false" do
                it "defaults the attribute value to false" do
                  User.attribute_reader(:is_awesome, :boolean, :default => false)
                  User.new.is_awesome.should be_false
                  User.new(:is_awesome => true).is_awesome.should be_true
                end
              end
            end

            context "when a :default is not supplied" do
              it "does not default the value" do
                User.attribute_reader(:nick_name, :string)
                User.new.nick_name.should be_nil
                User.new(:nick_name => "shorty").nick_name.should == "shorty"
              end
            end
          end
        end

        describe ".synthetic_attribute" do
          attr_reader :user, :attribute
          before do
            @attribute = User.synthetic_attribute :team_name do
              team.signal(:name)
            end
            @user = User.create(:team_id => "mangos")
          end

          it "adds a method to the Tuple that returns the value of the #signal returned by instance eval'ing the given block" do
            user.team_name.should == user.team.name
            new_name = "The Bananas"
            user.team.name = new_name
            user.team_name.should == new_name
          end

          it "adds a SyntheticAttribute to the #set.attributes" do
            User.set[:team_name].should == attribute
          end
        end

        describe ".relates_to_many" do
          it "creates an instance method representing the given Relation" do
            User.relates_to_many(:custom_photos) do
              Photo.set.where(Photo[:user_id].eq(id))
            end
            user = User.create(:id => "bob", :name => "Bob")
            user.custom_photos.should == Photo.set.where(photos_set[:user_id].eq("bob"))
          end

          it 'creates a "#{name}_relation" method to return the relation' do
            user = User.find("nathan")
            user.photos_relation.should == user.photos
          end

          context "when the Relation definition is invalid" do
            it "includes the definition backtrace in the error message" do
              User.relates_to_many(:invalid) {raise "An Error"}; definition_line = __LINE__
              lambda do
                User.new
              end.should raise_error(RuntimeError, Regexp.new("#{__FILE__}:#{definition_line}"))
            end
          end

          context "when subclassed" do
            it "creates an instance method representing the given Relation subclass" do
              user = Developer.create(:id => "jeff", :name => "Jeff")
              photo = Photo.create(:id => "jeff_photo", :user_id => "jeff", :name => "Jeff's Photo")
              user.photos.should == [photo]
            end
          end
        end

        describe ".relates_to_one" do
          attr_reader :photo
          before do
            @photo = Photo.find("nathan_photo_1")
          end

          it "defines a method named after the name which returns the Relation that is produced by instance-evaling the block" do
            photo.user.should_not be_nil
            photo.user.should == User.where(User[:id].eq(photo[:user_id]))
          end

          describe "the defined reader method" do
            context "when the produced Relation is #nil?" do
              it "returns nil" do
                users_set.delete(photo.user.tuple)
                photo.user_relation.should be_nil
                photo.user.class.should == NilClass
              end
            end

            context "when the produced Relation is not #nil?" do
              it "returns a SingletonRelation whose #operand is the block's return value" do
                Photo.class_eval do
                  relates_to_one :relates_to_one_user do
                    User.where(User[:id].eq(user_id))
                  end
                end

                photo = Photo.create(:user_id => "nathan")

                photo.relates_to_one_user.should_not be_nil
                photo.relates_to_one_user.class.should == Relations::SingletonRelation
                photo.relates_to_one_user.operand.should == User.where(User[:id].eq(photo[:user_id]))
              end
            end
          end

          it 'creates a "#{name}_relation" method to return the relation' do
            photo.user_relation.should == photo.user
          end

          context "when the Relation definition is invalid" do
            it "includes the definition backtrace in the error message" do
              User.relates_to_one(:invalid) {raise "An Error"}; definition_line = __LINE__
              lambda do
                User.new
              end.should raise_error(RuntimeError, Regexp.new("#{__FILE__}:#{definition_line}"))
            end
          end

          context "when subclassed" do
            it "creates an instance method representing the given Relation subclass" do
              user = Developer.create(:id => "jeff", :name => "Jeff")
              profile = Profile.create(:id => "jeff_profile", :owner_id => "jeff")
              user.profile.should == profile
            end
          end
        end

        describe ".has_many" do
          attr_reader :user
          before do
            @user = User.find("nathan")
          end

          it "assigns a HasMany instance on the PrimitiveTuple during initialization" do
            user.photos.class.should == Relations::HasMany
          end

          describe ":through option" do
            it "assigns a HasManyThrough instance on the PrimitiveTuple during initialization" do
              user.fans.class.should == Relations::HasManyThrough
            end
          end

          context "when passed a customization block" do
            it "calls the block on the default generated relation, using its return value as the instance relation" do
              user = User.find("nathan")
              user.active_accounts.should_not be_empty
              user.accounts.any? do |account|
                !account.active?
              end.should be_true
              user.active_accounts.each do |account|
                account.should be_active
              end
            end
          end
        end

        describe ".has_one" do
          attr_reader :user
          before do
            @user = User.find("nathan")
          end

          it "assigns a HasOne instance on the PrimitiveTuple during initialization" do
            user.profile.class.should == Relations::HasOne
          end

          describe "customization block" do
            context "when not passed a block" do
              it "returns a Selection on the target Relation where the foreign key Attribute is EqualTo the instance's #id" do
                user.photos.should == Photo.where(Photo[:user_id].eq(user[:id]))
              end
            end

            context "when passed a block" do
              describe "the reader method" do
                it "calls the block on the default generated Relation, and uses a SingletonRelation whose #operand is the return value of the block as its instance Relation" do
                  user.active_account.class.should == Relations::SingletonRelation
                  user.active_account.operand.should == Account.where(Account[:user_id].eq(user[:id])).where(Account.active?)

                  user_without_active_account = User.find("ross")
                  user_without_active_account.active_account.should be_nil
                end
              end
            end
          end
        end

        describe ".belongs_to" do
          attr_reader :profile, :user
          before do
            @profile = Profile.find("nathan_profile")
            @user = User.find("nathan")
          end

          it "assigns a BelongsTo instance on the PrimitiveTuple during initialization" do
            profile.owner.class.should == Relations::BelongsTo
          end

          describe "customization block" do
            context "when not passed a block" do
              it "returns a Selection on the target Relation where the foreign key Attribute is EqualTo the instance's #id" do
                profile.owner.should == user
              end
            end

            context "when passed a block" do
              describe "the reader method" do
                it "returns the result of the default Selection yielded to the block" do
                  profile.yoga_owner.should == User.where(User[:id].eq(profile[:owner_id])).where(User[:hobby].eq("Yoga"))
                  Profile.find("corey_profile").yoga_owner.should be_nil
                end
              end
            end
          end
        end

        describe ".create" do
          it "instantiates an instance of the Tuple with the given attributes and inserts it into its .set, then returns it" do
            User.find("ernie").should be_nil
            user = User.create(:id => "ernie", :name => "Ernie")
            User.find("ernie").should == user
          end
        end

        describe ".basename" do
          it "returns the last segment of name" do
            tuple_class = Class.new(PrimitiveTuple)
            stub(tuple_class).name {"Foo::Bar::Baz"}
            tuple_class.basename.should == "Baz"
          end
        end

        describe ".set" do
          context "when .member_of was not called" do
            attr_reader :tuple_class, :set
            before do
              @tuple_class = Class.new(PrimitiveTuple)
              stub(tuple_class).name {"MyShoe"}
              @set = tuple_class.set
            end

            it "returns a new Set whose name is underscored and pluralized class name" do
              set.name.should == "my_shoes"
            end

            it "retains the new Set" do
              set.should be_retained_by(tuple_class)
            end

            it "sets the #tuple_class of the new Set to self" do
              set.tuple_class.should == tuple_class
            end
          end

          context "when .member_of was called" do
            it "returns the passed-in Set" do
              set = Relations::Set.new(:sets)
              tuple_class = Class.new(PrimitiveTuple) do
                member_of(set)
              end
              tuple_class.set.should == set
            end
          end

          context "when subclassed" do
            context "when .member_of was not called on the subclass" do
              it "returns the superclass.set" do
                sub_class = Class.new(User)
                sub_class.set.should == User.set
              end
            end

            context "when .member_of was called on the subclass" do
              it "returns the passed-in Set" do
                sub_set = Relations::Set.new(:sub_users)
                sub_class = Class.new(User) do
                  member_of(sub_set)
                end
                sub_class.set.should == sub_set
              end
            end
          end
        end

        describe ".declare_fixtures" do
          it "delegates to #set" do
            fixtures_hash = {
              "joe" => {:name => "Joe"}  
            }
            mock.proxy(User.set).declare_fixtures(fixtures_hash)
            User.declare_fixtures(fixtures_hash)
          end
        end

        describe ".load_fixtures" do
          it "delegates to #set" do
            mock.proxy(User.set).load_fixtures
            User.load_fixtures
          end
        end
      end

      describe "Instance Methods" do
        before do
          User.superclass.should == PrimitiveTuple
          @tuple = User.new(:id => "nathan", :name => "Nathan")
        end

        describe "#initialize" do
          attr_reader :tuple
          before do
            @tuple = User.new(:id => "nathan", :name => "Nathan")
          end

          it "assigns a hash of attribute-value pairs corresponding to its Relation" do
            tuple[:id].should == "nathan"
            tuple[:name].should == "Nathan"
          end

          it "sets new? to true" do
            tuple.should be_new
          end

          it "sets dirty? to true" do
            tuple.should be_dirty
          end

          context "when Unison.test_mode? is true" do
            before do
              Unison.test_mode?.should be_true
            end

            it "if an #id is provided, honors it" do
              user = User.create(:id => "obama", :name => "Obama")
              user.id.should == "obama"
            end

            it "if no #id is provided, sets :id to a generated guid" do
              user = User.create(:name => "Obama")
              user.id.should_not be_nil
            end
          end

          context "when Unison.test_mode? is false" do
            before do
              Unison.test_mode = false
            end

            it "if an #id is provided, raises an error" do
              lambda do
                User.create(:id => "obama", :name => "Obama")
              end.should raise_error
            end
          end
        end

        describe "#composite?" do
          it "should be false" do
            tuple.should_not be_composite
          end
        end

        describe "#primitive?" do
          it "should be true" do
            tuple.should be_primitive
          end
        end

        describe "#[]" do
          context "when passed an Attribute defined on #relation" do
            it "returns the value" do
              tuple[User.set[:id]].should == "nathan"
              tuple[User.set[:name]].should == "Nathan"
            end
          end

          context "when passed an Attribute defined on a different #set" do
            it "raises an exception" do
              lambda do
                tuple[photos_set[:id]]
              end.should raise_error
            end
          end

          context "when passed #set" do
            it "returns self" do
              tuple[tuple.set].should == tuple
            end
          end

          context "when passed a Symbol corresponding to a name of an Attribute defined on #set" do
            it "returns the value" do
              tuple[:id].should == "nathan"
              tuple[:name].should == "Nathan"
            end
          end

          context "when passed a Symbol that does not correspond to a name of an Attribute defined on #set" do
            it "raises an exception" do
              lambda do
                tuple[:fantasmic]
              end.should raise_error
            end
          end

          context "when passed a Relation != to #set" do
            it "raises an exception" do
              lambda do
                tuple[photos_set]
              end.should raise_error
            end
          end
        end

        describe "#[]=" do
          attr_reader :retainer
          before do
            @retainer = Object.new
            tuple.retain_with(retainer)
          end

          after do
            tuple.release_from(retainer)
          end

          context "when passed an Attribute as the index argument" do
            it "delegates to #set_value on the PrimitiveField matching the given Attribute" do
              mock.proxy(tuple.field_for(tuple.set[:name])).set_value("New Name")
              tuple[tuple.set[:name]] = "New Name"
            end
          end

          context "when passed a Symbol as the index argument" do
            it "delegates to #set_value on the PrimitiveField matching the Attribute named by the Symbol" do
              mock.proxy(tuple.field_for(tuple.set[:name])).set_value("New Name")
              tuple[:name] = "New Name"
            end
          end

          context "when the passed in value is different than the original value" do
            attr_reader :new_value
            before do
              @new_value = "Corey"
              tuple[:name].should_not == new_value
            end

            it "triggers the on_update event" do
              update_args = []
              tuple.on_update(retainer) do |attribute, old_value, new_value|
                update_args.push [attribute, old_value, new_value]
              end

              old_value = tuple[:id]
              new_value = "#{tuple[:id]}_id"
              tuple[:id] = new_value
              update_args.should == [[tuple.set[:id], old_value, new_value]]
            end
          end

          context "when the passed in value is the same than the original value" do
            it "does not trigger the on_update event" do
              tuple.on_update(retainer) do |attribute, old_value, new_value|
                raise "Don't taze me bro"
              end

              tuple[:name] = tuple[:name]
            end
          end
        end

        describe "#dirty?" do
          context "when any PrimitiveField is #dirty?" do
            it "returns true" do
              tuple.primitive_fields.any? do |field|
                field.dirty?
              end.should be_true
              tuple.should be_dirty
            end
          end

          context "when no #primitive_fields are #dirty?" do
            it "returns false" do
              tuple.pushed
              tuple.primitive_fields.any? do |field|
                field.dirty?
              end.should be_false
              tuple.should_not be_dirty
            end
          end
        end

        describe "#push" do
          it "calls Unison.origin.push(self)" do
            mock.proxy(origin).push(tuple)
            tuple.push
          end

          it "sets new? to false" do
            tuple.should be_new
            tuple.push
            tuple.should_not be_new
          end

          it "sets dirty? to false" do
            tuple.push
            tuple[:name] = "#{tuple[:name]} with addition"
            tuple.should be_dirty
            tuple.push
            tuple.should_not be_dirty
          end

          it "returns self" do
            tuple.push.should == tuple
          end
        end

        describe "#delete" do
          it "removes itself from its #set" do
            tuple = User.find("nathan")
            tuple.set.should include(tuple)
            tuple.delete
            tuple.set.should_not include(tuple)
          end
        end

        describe "#pushed" do
          it "sets new? to false" do
            tuple.should be_new
            tuple.pushed
            tuple.should_not be_new
          end

          it "sets dirty? to false" do
            tuple.pushed
            tuple[:name] = "#{tuple[:name]} with addition"
            tuple.should be_dirty
            tuple.pushed
            tuple.should_not be_dirty
          end

          it "returns self" do
            tuple.pushed.should == tuple
          end
        end

        describe "#has_attribute?" do
          it "delegates to #set" do
            tuple.has_attribute?(:id).should == tuple.set.has_attribute?(:id)
          end
        end

        describe "#has_synthetic_attribute?" do
          it "delegates to #set" do
            tuple.has_synthetic_attribute?(:conqueror_name).should == tuple.set.has_synthetic_attribute?(:conqueror_name)
          end
        end

        describe "#persistent_hash_representation" do
          it "returns a Hash of attribute => value pairs for only #primitive_fields" do
            tuple.persistent_hash_representation.should == {
              :id => "nathan",
              :hobby => "Bomb construction",
              :name => "Nathan",
              :team_id => nil,
              :developer => nil,
              :show_fans => true
            }
          end
        end

        describe "#hash_representation" do
          it "returns a Hash of attribute => value pairs for all #fields" do
            hash_representation = tuple.hash_representation
            hash_representation.keys.length.should == tuple.fields.length
            tuple.fields.each do |field|
              hash_representation[field.attribute.name].should == field.value
            end
          end
        end

        describe "#fields" do
          it "returns an Array of all Fields" do
            publicize tuple, :fields_hash
            tuple.fields.should == tuple.fields_hash.values
          end
        end

        describe "#primitive_fields" do
          it "returns an Array of all PrimitiveFields from the #fields hash" do
            tuple.fields.any? {|field| field.instance_of?(SyntheticField)}.should be_true
            primitive_fields = tuple.primitive_fields
            primitive_fields.should_not be_empty
            primitive_fields.each do |field|
              field.class.should == PrimitiveField
            end
          end
        end

        describe "#synthetic_fields" do
          it "returns an Array of all SyntheticFields from the #fields hash" do
            tuple.fields.any? {|field| field.instance_of?(PrimitiveField)}.should be_true
            synthetic_fields = tuple.synthetic_fields
            synthetic_fields.should_not be_empty
            synthetic_fields.each do |field|
              field.class.should == SyntheticField
            end
          end
        end

        describe "#field_for" do
          context "when passed an Attribute in the PrimitiveTuple" do
            it "returns the Field corresponding to the Attribute" do
              attribute = User[:id]
              field = tuple.field_for(attribute)
              field.tuple.should == tuple
              field.attribute.should == attribute
            end
          end

          context "when passed a Symbol that names an Attribute in the PrimitiveTuple" do
            it "returns the Field corresponding to the Attribute" do
              attribute = User[:id]
              field = tuple.field_for(:id)
              field.tuple.should == tuple
              field.attribute.should == attribute
            end
          end

          context "when passed an Attribute that is not in the PrimitiveTuple" do
            it "raises an ArgumentError" do
              lambda do
                field = tuple.field_for(Photo[:id])
              end.should raise_error(ArgumentError)
            end
          end

          context "when passed a Symbol that does not name an Attribute in the PrimitiveTuple" do
            it "raises an ArgumentError" do
              lambda do
                field = tuple.field_for(:hello_there)
              end.should raise_error(ArgumentError)
            end
          end
        end

        describe "#<=>" do
          it "sorts on the :id attribute" do
            tuple_1 = Photo.find("nathan_photo_1")
            tuple_2 = Photo.find("nathan_photo_2")

            (tuple_1 <=> tuple_2).should == -1
            (tuple_2 <=> tuple_1).should == 1
            (tuple_1 <=> tuple_1).should == 0
          end
        end

        describe "#signal" do
          attr_reader :user, :signal
          before do
            @user = User.find("nathan")
          end

          context "when passed a Symbol" do
            before do
              @signal = user.signal(:name)
            end

            context "when the Symbol is the #name of a PrimitiveAttribute in the PrimitiveTuple's #set" do
              it "returns an AttributeSignal for the corresponding PrimitiveAttribute" do
                signal.attribute.should == users_set[:name]
              end

              context "when passed a block" do
                it "returns a DerivedSignal with the AttributeSignal as its #source" do
                  derived_signal = user.signal(:name) do |value|
                    "#{value} the Terrible"
                  end
                  derived_signal.class.should == Signals::DerivedSignal
                  derived_signal.value.should == "#{user.name} the Terrible"
                end
              end
            end

            context "when the Symbol is the #name of a SyntheticAttribute in the PrimitiveTuple's #set" do
              before do
                User.synthetic_attribute :team_name do
                  team.signal(:name)
                end
                @user = User.create(:team_id => "mangos")
              end

              it "returns the Signal defined by the SyntheticAttribute for this PrimitiveTuple" do
                signal = user.signal(:team_name)
                signal.retain_with(retainer = Object.new)

                signal.value.should == user.team.name
                on_change_args = []
                signal.on_change(retainer) do |*args|
                  on_change_args.push(args)
                end

                expected_old_name = user.team.name
                new_name = "The Tacos"
                user.team.name = new_name
                on_change_args.should == [[new_name]]

                signal.release_from(retainer)
              end

              context "when passed a block" do
                it "returns a DerivedSignal with the signal associated with the synthetic attribute as its #source" do
                  derived_signal = user.signal(:team_name) do |value|
                    "#{value} Suck!"
                  end
                  derived_signal.class.should == Signals::DerivedSignal
                  derived_signal.value.should == "#{user.team_name} Suck!"
                end
              end
            end

            context "when the Symbol names a SingletonRelation" do
              it "returns a SingletonRelationSignal with the Relation as its #value" do
                signal = user.signal(:team)
                signal.class.should == Signals::SingletonRelationSignal
                signal.value.should == user.team
              end
            end

            context "when the Symbol is not the #name of any kind of attribute or relation" do
              it "raises an ArgumentError" do
                lambda do
                  @signal = user.signal(:bullshit)
                end.should raise_error(ArgumentError)
              end
            end
          end

          context "when passed an PrimitiveAttribute" do
            context "when the PrimitiveAttribute belongs to the PrimitiveTuple's #set" do
              before do
                @signal = user.signal(users_set[:name])
              end

              it "returns an AttributeSignal with #attribute set to the passed in PrimitiveAttribute" do
                signal.attribute.should == users_set[:name]
              end

              context "when passed a block" do
                it "returns a DerivedSignal with the AttributeSignal as its #source" do
                  derived_signal = user.signal(users_set[:name]) do |value|
                    "#{value} the Terrible"
                  end
                  derived_signal.class.should == Signals::DerivedSignal
                  derived_signal.value.should == "#{user.name} the Terrible"
                end
              end
            end

            context "when the PrimitiveAttribute does not belong to the PrimitiveTuple's #set" do
              it "raises an ArgumentError" do
                lambda do
                  @signal = user.signal(photos_set[:name])
                end.should raise_error(ArgumentError)
              end
            end
          end

          context "when passed a SyntheticAttribute" do
            before do
              User.synthetic_attribute :team_name do
                team.signal(:name)
              end
              @user = User.create(:team_id => "mangos")
            end

            it "returns the Signal defined by the SyntheticAttribute for this PrimitiveTuple" do
              signal = user.signal(User[:team_name])
              signal.retain_with(retainer = Object.new)

              signal.value.should == user.team.name
              on_change_args = []
              signal.on_change(retainer) do |*args|
                on_change_args.push(args)
              end

              expected_old_name = user.team.name
              new_name = "The Tacos"
              user.team.name = new_name
              on_change_args.should == [[new_name]]

              signal.release_from(retainer)
            end

            context "when passed a block" do
              it "returns a DerivedSignal with the signal associated with the synthetic attribute as its #source" do
                derived_signal = user.signal(:team_name) do |value|
                  "#{value} Suck!"
                end
                derived_signal.class.should == Signals::DerivedSignal
                derived_signal.value.should == "#{user.team_name} Suck!"
              end
            end
          end
        end

        describe "#bind" do
          context "when passed in expression is an Attribute" do
            it "retrieves the value for an Attribute defined on the set of the Tuple class" do
              tuple.bind(User.set[:id]).should == "nathan"
              tuple.bind(User.set[:name]).should == "Nathan"
            end
          end

          context "when passed in expression is not an Attribute" do
            it "is the identity function" do
              tuple.bind(:id).should == :id
              tuple.bind("nathan").should == "nathan"
              tuple.bind("Hi").should == "Hi"
            end
          end
        end

        describe "#==" do
          attr_reader :other_tuple
          context "when other is not a Tuple" do
            it "returns false" do
              other_object = Object.new
              tuple.should_not == other_object
            end
          end

          context "when other Tuple#fields == #fields" do
            before do
              @other_tuple = User.new(:id => "nathan", :name => "Nathan")
              publicize other_tuple, :fields
              other_tuple.fields.should == tuple.fields
            end

            it "returns true" do
              tuple.should == other_tuple
            end
          end

          context "when other Tuple#fields != #fields" do
            before do
              @other_tuple = User.new(:id => "nathan_clone", :name => "Nathan's Clone")
              publicize other_tuple, :fields
              other_tuple.fields.should_not == tuple.fields
            end

            it "returns false" do
              tuple.should_not == other_tuple
            end
          end
        end
      end
    end
  end
end
