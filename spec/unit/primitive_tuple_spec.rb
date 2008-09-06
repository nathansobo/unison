require File.expand_path("#{File.dirname(__FILE__)}/../unison_spec_helper")

module Unison
  module PrimitiveTuple
    describe Base do
      attr_reader :tuple

      describe "Class Methods" do
        describe ".new" do
          context "when .polymorphic_allocate is overridden" do
            it "returns the object that is returned by .polymorphic_allocate" do
              other_class = Class.new(PrimitiveTuple::Base) do
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
            mock.proxy(User.set).has_attribute(:nick_name, :string)
            User.attribute(:nick_name, :string)
          end

          context "when passed :default option" do
            it "defaults the Attribute value to the passed-in :default option value" do
              User.attribute_reader(:nick_name, :string, :default => "Bobo")
              User.new.nick_name.should == "Bobo"
            end

            context "when subclassed" do
              it "defaults the Attribute value to the :default option value passed-in to the superclass" do
                User.attribute_reader(:nick_name, :string, :default => "Bobo")
                Developer.new.nick_name.should == "Bobo"
              end
            end
          end
        end

        describe ".attribute_reader" do
          it "creates an attribute on the .set" do
            mock.proxy(User.set).has_attribute(:nick_name, :string)
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

        describe ".attribute_writer" do
          it "creates an attribute on the .set" do
            mock.proxy(User.set).has_attribute(:nick_name, :string)
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
            mock.proxy(User.set).has_attribute(:nick_name, :string).at_least(1)
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
        
        describe ".relates_to_n" do
          it "creates an instance method representing the given Relation" do
            user = User.find(1)
            user.photos.should == photos_set.where(photos_set[:user_id].eq(1))
          end

          context "when the Relation definition is invalid" do
            it "includes the definition backtrace in the error message" do
              User.relates_to_n(:invalid) {raise "An Error"}; definition_line = __LINE__
              lambda do
                User.new
              end.should raise_error(RuntimeError, Regexp.new("#{__FILE__}:#{definition_line}"))
            end
          end

          context "when subclassed" do
            it "creates an instance method representing the given Relation subclass" do
              user = Developer.create(:id => 100, :name => "Jeff")
              photo = Photo.create(:id => 100, :user_id => 100, :name => "Jeff's Photo")
              user.photos.should == [photo]
            end
          end
        end

        describe ".relates_to_1" do
          attr_reader :photo
          before do
            @photo = Photo.find(1)
          end

          it "defines a method named after the name which returns the Relation that is produced by instance-evaling the block" do
            photo.user.should_not be_nil
            photo.user.should == User.where(User[:id].eq(photo[:user_id]))
          end

          it "causes the Relation to be treated as a singleton" do
            photo.user.should be_singleton
          end

          context "when the Relation definition is invalid" do
            it "includes the definition backtrace in the error message" do
              User.relates_to_1(:invalid) {raise "An Error"}; definition_line = __LINE__
              lambda do
                User.new
              end.should raise_error(RuntimeError, Regexp.new("#{__FILE__}:#{definition_line}"))
            end
          end

          context "when subclassed" do
            it "creates an instance method representing the given Relation subclass" do
              user = Developer.create(:id => 100, :name => "Jeff")
              profile = Profile.create(:id => 100, :owner_id => 100)
              user.profile.should == profile
            end
          end
        end

        describe ".has_many" do
          attr_reader :user
          before do
            @user = User.find(1)
          end

          it "does not create a singleton Selection" do
            user.photos.should_not be_singleton
          end

          it "creates a reader method with the given name" do
            user.should respond_to(:photos)
          end

          describe ":foreign_key option" do
            context "when not passed :foreign_key" do
              describe "the reader method" do
                it "returns a Selection on the target Relation where the foreign key Attribute Eq's the instance's #id" do
                  user.photos.should == Photo.where(Photo[:user_id].eq(user[:id]))
                end
              end
            end

            context "when passed a :foreign_key option" do
              describe "the reader method" do
                it "returns a Selection on the target Relation where the foreign key Attribute Eq's the instance's #id" do
                  user.friendships_to_me.should == Friendship.where(Friendship[:to_id].eq(user[:id]))
                end
              end
            end
          end

          describe ":class_name option" do
            context "when not passed a :class_name option" do
              it "chooses the target Relation by singularizing and classifying the given name" do
                user.photos.operand.should == Photo.set
              end
            end

            context "when passed a :class_name option" do
              it "uses the #set of the class with the given name as the target Relation" do
                user.friendships_to_me.operand.should == Friendship.set
              end
            end
          end

          describe "customization block" do
            context "when not passed a block" do
              it "returns a Selection on the target Relation where the foreign key Attribute Eq's the instance's #id" do
                user.photos.should == Photo.where(Photo[:user_id].eq(user[:id]))
              end
            end

            context "when passed a block" do
              describe "the reader method" do
                it "returns the result of the default Selection yielded to the block" do
                  user.active_accounts.should == Account.where(Account[:user_id].eq(user[:id])).where(Account.active?)
                end
              end
            end
          end

          describe ":through option" do
            context "when passed :through, :class_name, and :foreign_key options" do
              context "when the target Relation is the owner of the :foreign_key" do
                it "returns members of the target Relation (associated with :class_name) whose foreign key (explicated by :foreign_key) equals the id of members of the through Relation" do
                  team = Team.find(1)
                  team.friendships_from_users.sort_by(&:id).should == team.users.map(&:friendships_from_me).flatten.sort_by(&:id)
                end
              end

              context "when the through Relation is the owner of the :foreign_key" do
                it "returns members of the target Relation (associated with :class_name) whose id equals the foreign key (explicated by :foreign_key) of members of the through Relation" do
                  user.fans.should == user.friendships_to_me.join(User.set).on(Friendship[:from_id].eq(User[:id])).project(User.set)
                  user.fans.should_not be_empty
                  user.fans.sort_by(&:id).should == user.friendships_to_me.map {|friendship| friendship.from.tuples.first}.uniq.sort_by(&:id)
                  user.fans.each do |fan|
                    fan.heroes.should include(user)
                  end
                end
              end
            end

            context "when passed :through" do
              context "when the target Relation is the owner of the :foreign_key" do
                it "returns members of the target Relation whose foreign key equals the id of members of the through Relation" do
                  team = Team.find(1)
                  team.photos.sort_by(&:id).should == team.users.map(&:photos).flatten.sort_by(&:id)
                end
              end

              context "when the through Relation is the owner of the :foreign_key" do
                it "returns members of the target Relation whose id equals the foreign key of members of the through Relation" do
                  user.cameras.should_not be_empty
                  user.cameras.sort_by(&:id).should == user.photos.map {|photo| photo.camera.tuples.first}.uniq.sort_by(&:id)
                end
              end
            end
          end

          context "when passed a customization block" do
            it "calls the block on the default generated relation, using its return value as the instance relation" do
              user = User.find(1)
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
            @user = User.find(1)
          end

          it "creates a singleton Selection" do
            user.profile.should be_singleton
          end

          it "creates a reader method with the given name" do
            user.should respond_to(:profile)
          end

          describe ":foreign_key option" do
            context "when not passed :foreign_key" do
              describe "the reader method" do
                it "returns a Selection on the target Relation where the foreign key Attribute Eq's the instance's #id" do
                  user.life_goal.should == LifeGoal.where(LifeGoal[:user_id].eq(user[:id]))
                end
              end
            end

            context "when passed a :foreign_key option" do
              describe "the reader method" do
                it "returns a Selection on the target Relation where the foreign key Attribute Eq's the instance's #id" do
                  user.profile.should == Profile.where(Profile[:owner_id].eq(user[:id]))
                end
              end
            end
          end

          describe ":class_name option" do
            context "when not passed a :class_name option" do
              it "chooses the target Relation by singularizing and classifying the given name" do
                user.profile.operand.should == Profile.set
              end
            end

            context "when passed a :class_name option" do
              it "uses the #set of the class with the given name as the target Relation" do
                user.profile_alias.operand.should == Profile.set
              end
            end
          end

          describe "customization block" do
            context "when not passed a block" do
              it "returns a Selection on the target Relation where the foreign key Attribute Eq's the instance's #id" do
                user.photos.should == Photo.where(Photo[:user_id].eq(user[:id]))
              end
            end

            context "when passed a block" do
              describe "the reader method" do
                it "calls the block on the default generated relation, using its return value as the instance relation" do
                  user.active_account.should be_singleton
                  user.active_account.should == Account.where(Account[:user_id].eq(user[:id])).where(Account.active?)

                  user_without_active_account = User.find(3)
                  user_without_active_account.active_account.should be_nil
                end
              end
            end
          end
        end

        describe ".belongs_to" do
          attr_reader :profile, :user
          before do
            @profile = Profile.find(1)
            @user = User.find(1)
          end

          it "creates a singleton Selection on the target Set where the target's id matches the instance's foreign key" do
            profile.owner.should be_singleton
            profile.owner.should == user
          end

          it "creates a reader method with the given name" do
            profile.should respond_to(:owner)
          end

          describe ":foreign_key option" do
            context "when not passed :foreign_key" do
              describe "the reader method" do
                it "returns a Selection on the target Relation where the foreign key Attribute Eq's the instance's #id" do
                  friendship = Friendship.find(1)
                  friendship.from.should == user
                end
              end
            end

            context "when passed a :foreign_key option" do
              describe "the reader method" do
                it "returns a Selection on the target Relation where the foreign key Attribute Eq's the instance's #id" do
                  account = Account.find(1)
                  account.owner.should == user
                end
              end
            end
          end

          describe ":class_name option" do
            context "when not passed a :class_name option" do
              it "chooses the target Relation by singularizing and classifying the given name" do
                photo = Photo.find(1)
                photo.user.operand.should == User.set
              end
            end

            context "when passed a :class_name option" do
              it "uses the #set of the class with the given name as the target Relation" do
                profile.owner.operand.should == User.set
              end
            end
          end

          describe "customization block" do
            context "when not passed a block" do
              it "returns a Selection on the target Relation where the foreign key Attribute Eq's the instance's #id" do
                profile.owner.should == user
              end
            end

            context "when passed a block" do
              describe "the reader method" do
                it "returns the result of the default Selection yielded to the block" do
                  profile.yoga_owner.should == User.where(User[:id].eq(profile[:owner_id])).where(User[:hobby].eq("Yoga"))
                  Profile.find(2).yoga_owner.should be_nil
                end
              end
            end
          end
        end

        describe ".create" do
          it "instantiates an instance of the Tuple with the given attributes and inserts it into its .set, then returns it" do
            User.find(100).should be_nil
            user = User.create(:id => 100, :name => "Ernie")
            User.find(100).should == user
          end
        end

        describe ".basename" do
          it "returns the last segment of name" do
            tuple_class = Class.new(PrimitiveTuple::Base)
            stub(tuple_class).name {"Foo::Bar::Baz"}
            tuple_class.basename.should == "Baz"
          end
        end

        describe ".set" do
          context "when .member_of was not called" do
            it "returns nil" do
              tuple_class = Class.new(PrimitiveTuple::Base)
              tuple_class.set.should be_nil
            end
          end

          context "when .member_of was called" do
            it "returns the passed-in Set" do
              set = Relations::Set.new(:sets)
              tuple_class = Class.new(PrimitiveTuple::Base) do
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
      end

      describe "Instance Methods" do
        before do
          User.superclass.should == PrimitiveTuple::Base
          @tuple = User.new(:id => 1, :name => "Nathan")
        end

        describe "#initialize" do
          attr_reader :tuple
          before do
            @tuple = User.new(:id => 1, :name => "Nathan")
          end

          it "assigns a hash of attribute-value pairs corresponding to its Relation" do
            tuple[:id].should == 1
            tuple[:name].should == "Nathan"
          end

          it "sets new? to true" do
            tuple.should be_new
          end

          it "sets dirty? to true" do
            tuple.should_not be_dirty
          end

          context "when Unison.test_mode? is true" do
            before do
              Unison.test_mode?.should be_true
            end

            it "if an #id is provided, honors it" do
              user = User.create(:id => 100, :name => "Obama")
              user.id.should == 100
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
                User.create(:id => 100, :name => "Obama")
              end.should raise_error
            end
          end
        end

        describe "#compound?" do
          it "should be false" do
            tuple.should_not be_compound
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
              tuple[User.set[:id]].should == 1
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
              tuple[:id].should == 1
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

          context "when the passed in value is different than the original value" do
            attr_reader :new_value
            before do
              @new_value = "Corey"
              tuple[:name].should_not == new_value
            end

            it "sets the value for an Attribute defined on the set of the Tuple class" do
              tuple[User.set[:id]] = 2
              tuple[User.set[:id]].should == 2
              tuple[User.set[:name]] = new_value
              tuple[User.set[:name]].should == new_value
            end

            it "sets the value for a Symbol corresponding to a name of an Attribute defined on the #set of the Tuple class" do
              tuple[:id] = 2
              tuple[:id].should == 2
              tuple[:name] = new_value
              tuple[:name].should == new_value
            end

            it "triggers the on_update event" do
              update_args = []
              tuple.on_update(retainer) do |attribute, old_value, new_value|
                update_args.push [attribute, old_value, new_value]
              end

              old_value = tuple[:id]
              new_value = tuple[:id] + 1
              tuple[:id] = new_value
              update_args.should == [[tuple.set[:id], old_value, new_value]]
            end

            context "when not new? and not dirty?" do
              it "sets dirty? to true" do
                tuple.pushed.should_not be_new
                tuple.should_not be_dirty

                tuple[:name] = new_value
                tuple.should be_dirty
              end
            end

            context "when new? and not dirty?" do
              it "does not set dirty? to true" do
                tuple.should be_new
                tuple.should_not be_dirty
                
                tuple[:name] = new_value
                tuple.should_not be_dirty
              end
            end
          end

          context "when the passed in value is the same than the original value" do
            it "does not trigger the on_update event" do
              tuple.on_update(retainer) do |attribute, old_value, new_value|
                raise "Dont call me"
              end
              
              tuple[:name] = tuple[:name]
            end

            context "when not new? and not dirty?" do
              it "does not set dirty? to true" do
                tuple.pushed.should_not be_new
                tuple.should_not be_dirty

                tuple[:name] = tuple[:name]
                tuple.should_not be_dirty
              end
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

        describe "#attributes" do
          it "returns the #attribute_values, keyed by the name of their corresponding Attribute" do
            expected_attributes = {}
            tuple.send(:attribute_values).each do |attribute, value|
              expected_attributes[attribute.name] = value
            end
            expected_attributes.should_not be_empty

            tuple.attributes.should == expected_attributes
          end
        end

        describe "#<=>" do
          it "sorts on the :id attribute" do
            tuple_1 = Photo.find(1)
            tuple_2 = Photo.find(2)

            (tuple_1 <=> tuple_2).should == -1
            (tuple_2 <=> tuple_1).should == 1
            (tuple_1 <=> tuple_1).should == 0
          end
        end

        describe "#signal" do
          attr_reader :user, :signal
          before do
            @user = User.find(1)
          end

          context "when passed a Symbol" do
            before do
              @signal = user.signal(:name)
            end

            it "returns a Signal with the corresponding Attribute from the Tuple's Relation" do
              signal.attribute.should == users_set[:name]
            end
          end

          context "when passed an Attribute from the Relation" do
            before do
              @signal = user.signal(users_set[:name])
            end

            it "returns a Signal with #attribute set to the passed in Attribute" do
              signal.attribute.should == users_set[:name]
            end
          end

          context "when passed an Attribute not from the Relation" do
            it "raises an ArgumentError" do
              lambda do
                @signal = user.signal(photos_set[:name])
              end.should raise_error(ArgumentError)
            end
          end
        end

        describe "#bind" do
          context "when passed in expression is an Attribute" do
            it "retrieves the value for an Attribute defined on the set of the Tuple class" do
              tuple.bind(User.set[:id]).should == 1
              tuple.bind(User.set[:name]).should == "Nathan"
            end
          end

          context "when passed in expression is not an Attribute" do
            it "is the identity function" do
              tuple.bind(:id).should == :id
              tuple.bind(1).should == 1
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

          context "when other Tuple#attribute_values == #attribute_values" do
            before do
              @other_tuple = User.new(:id => 1, :name => "Nathan")
              other_tuple.send(:attribute_values).should == tuple.send(:attribute_values)
            end

            it "returns true" do
              tuple.should == other_tuple
            end
          end

          context "when other Tuple#attributes != #attributes" do
            before do
              @other_tuple = User.new(:id => 100, :name => "Nathan's Clone")
              other_tuple.send(:attribute_values).should_not == tuple.send(:attribute_values)
            end

            it "returns false" do
              tuple.should_not == other_tuple
            end
          end
        end

        describe "#select_children" do
          attr_reader :user
          before do
            @user = User.find(1)
          end

          it "does not create a singleton Selection" do
            user.select_children(Account).should_not be_singleton
          end

          context "when passed a Tuple" do
            it "creates a Selection on the target Set where the foreign key matches the instances' id" do
              accounts = user.select_children(Account)
              accounts.should_not be_empty
              accounts.should == accounts_set.where(accounts_set[:user_id].eq(user[:id]))
            end
          end

          context "when passed a Relation" do
            it "creates a Selection on the target Relation where the foreign key matches the instances' id" do
              accounts = user.select_children(Account.set)
              accounts.should_not be_empty
              accounts.should == accounts_set.where(accounts_set[:user_id].eq(user[:id]))
            end
          end

          context "when passed :foreign_key option" do
            it "returns the Tuples in the set that match the instance's foreign_key value" do
              friendships_to_me = user.select_children(Friendship, :foreign_key => :to_id)
              friendships_to_me.should_not be_empty
              friendships_to_me.should == friendships_set.where(
                friendships_set[:to_id].eq(user[:id])
              )
            end
          end
        end

        describe "#select_child" do
          attr_reader :user
          before do
            @user = User.find(1)
          end

          it "creates a singleton Selection on the target Set where the target Set id matches the instance's default foreign key attribute value" do
            profile = user.select_child(Account)
            profile.should be_singleton
            profile.should == Account.find(1)
          end

          context "when passed :foreign_key option" do
            it "creates a singleton Selection on the target Set where the target Set id matches the instance's passed in foreign_key attribute value" do
              profile = user.select_child(Profile, :foreign_key => :owner_id)
              profile.should_not be_nil
              profile.should == profiles_set.where(profiles_set[:owner_id].eq(user[:id])).singleton
            end
          end
        end

        describe "#select_parent" do
          context "when passed a :foreign_key" do
            it "creates a singleton Selection on the target Set where the instance id matches the target Set's passed in foreign_key attribute value" do
              friendship = Friendship.find(1)
              from_user = friendship.select_parent(User, :foreign_key => :from_id)
              from_user.should == User.find(friendship.from_id)
            end
          end
        end

        describe "#initialize_attribute_values" do
          it "transforms Symbol keys into their corresponding Attribute objects" do
            user = User.new
            publicize user, :initialize_attribute_values

            dont_allow(user).__send__(:[]=, :name, "Einstein")
            mock.proxy(user).__send__(:[]=, User[:name], "Einstein")
            stub.proxy(user).__send__(:[]=, anything, anything)
            user.initialize_attribute_values(:name => "Einstein")
          end
        end
      end
    end
  end
end
