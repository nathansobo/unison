require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

module Unison
  module PrimitiveTuple
    describe Base do
      attr_reader :tuple

      describe "Class Methods" do
        describe ".member_of" do
          it "associates the Tuple class with a relation and vice-versa" do
            users_set = User.relation
            users_set.name.should == :users
            users_set.tuple_class.should == User
          end
        end

        describe ".attribute" do
          it "delegates to .relation" do
            mock.proxy(User.relation).attribute(:nick_name, :string)
            User.attribute(:nick_name, :string)
          end
        end

        describe ".attribute_reader" do
          it "creates an attribute on the .relation" do
            mock.proxy(User.relation).attribute(:nick_name, :string)
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
        end

        describe ".attribute_writer" do
          it "creates an attribute on the .relation" do
            mock.proxy(User.relation).attribute(:nick_name, :string)
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
        end

        describe ".attribute_accessor" do
          it "creates an attribute on the .relation" do
            mock.proxy(User.relation).attribute(:nick_name, :string).at_least(1)
            User.attribute_accessor(:nick_name, :string)
          end

          it "adds a reader and a writer method to the Tuple" do
            User.attribute_accessor(:nick_name, :string)
            user = User.new(:nick_name => "Bob")
            user.nick_name = "Jane"
            user.nick_name.should == "Jane"
            user[:nick_name].should == "Jane"
          end
        end
        
        describe ".relates_to_n" do
          it "creates an instance method representing the given relation" do
            user = User.find(1)
            user.photos.should == photos_set.where(photos_set[:user_id].eq(1))
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
                  user.to_friendships.should == Friendship.where(Friendship[:to_id].eq(user[:id]))
                end
              end
            end
          end

          describe ":class_name option" do
            context "when not passed a :class_name option" do
              it "chooses the target Relation by singularizing and classifying the given name" do
                user.photos.operand.should == Photo.relation
              end
            end

            context "when passed a :class_name option" do
              it "uses the #relation of the class with the given name as the target Relation" do
                user.to_friendships.operand.should == Friendship.relation
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
                user.profile.operand.should == Profile.relation
              end
            end

            context "when passed a :class_name option" do
              it "uses the #relation of the class with the given name as the target Relation" do
                user.profile_alias.operand.should == Profile.relation
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
                  user.active_account.should be_singleton
                  user.active_account.should == Account.where(Account[:user_id].eq(user[:id])).where(Account.active?)
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
                photo.user.operand.should == User.relation
              end
            end

            context "when passed a :class_name option" do
              it "uses the #relation of the class with the given name as the target Relation" do
                profile.owner.operand.should == User.relation
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
                end
              end
            end
          end
        end

        describe ".create" do
          it "instantiates an instance of the Tuple with the given attributes and inserts it into its .relation, then returns it" do
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

          it "assigns a hash of attribute-value pairs corresponding to its relation" do
            tuple[:id].should == 1
            tuple[:name].should == "Nathan"
          end

          it "instantiates and retains its #instance_relations" do
            relations = tuple.send(:instance_relations)
            relations.should_not be_empty
            relations.each do |relation_name, relation|
              tuple.send(relation_name).should be_retained_by(tuple)
            end
          end

          it "instantiates and retains its #singleton_instance_relations" do
            relations = tuple.send(:singleton_instance_relations)
            relations.should_not be_empty
            relations.each do |relation_name, relation|
              tuple.send(relation_name).should be_retained_by(tuple)
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
          it "retrieves the value for an Attribute defined on the relation of the Tuple class" do
            tuple[User.relation[:id]].should == 1
            tuple[User.relation[:name]].should == "Nathan"
          end

          it "retrieves the value for a Symbol corresponding to a name of an Attribute defined on the relation of the Tuple class" do
            tuple[:id].should == 1
            tuple[:name].should == "Nathan"
          end
        end

        describe "#[]=" do
          it "sets the value for an Attribute defined on the relation of the Tuple class" do
            tuple[User.relation[:id]] = 2
            tuple[User.relation[:id]].should == 2
            tuple[User.relation[:name]] = "Corey"
            tuple[User.relation[:name]].should == "Corey"
          end

          it "sets the value for a Symbol corresponding to a name of an Attribute defined on the relation of the Tuple class" do
            tuple[:id] = 2
            tuple[:id].should == 2
            tuple[:name] = "Corey"
            tuple[:name].should == "Corey"
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

          describe ".on_update" do
            context "when the Signal#attribute value is changed" do
              it "invokes the block" do
                on_update_arguments = nil
                user.signal(:name).on_update do |user, old_value, new_value|
                  on_update_arguments = [user, old_value, new_value]
                end

                old_name = user[:name]
                user[:name] = "Wilhelm"
                on_update_arguments.should == [user, old_name, "Wilhelm"]
              end
            end

            context "when another Attribute value is changed" do
              it "does not invoke the block" do
                user.signal(:name).on_update do |user, old_value, new_value|
                  raise "I should not be Invoked"
                end

                user[:id] = 100
              end
            end
          end
        end

        describe "#bind" do
          context "when passed in expression is an Attribute" do
            it "retrieves the value for an Attribute defined on the relation of the Tuple class" do
              tuple.bind(User.relation[:id]).should == 1
              tuple.bind(User.relation[:name]).should == "Nathan"
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

          context "when other Tuple#attributes == #attributes" do
            before do
              @other_tuple = User.new(:id => 1, :name => "Nathan")
              other_tuple.attributes.should == tuple.attributes
            end

            it "returns true" do
              tuple.should == other_tuple
            end
          end

          context "when other Tuple#attributes != #attributes" do
            before do
              @other_tuple = User.new(:id => 100, :name => "Nathan's Clone")
              other_tuple.attributes.should_not == tuple.attributes
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
              accounts = user.select_children(Account.relation)
              accounts.should_not be_empty
              accounts.should == accounts_set.where(accounts_set[:user_id].eq(user[:id]))
            end
          end

          context "when passed :foreign_key option" do
            it "returns the Tuples in the relation that match the instance's foreign_key value" do
              to_friendships = user.select_children(Friendship, :foreign_key => :to_id)
              to_friendships.should_not be_empty
              to_friendships.should == friendships_set.where(
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
              profile.should == profiles_set.where(profiles_set[:owner_id].eq(user[:id])).treat_as_singleton
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

        describe "#on_update" do
          it "returns a Subscription" do
            tuple.on_update {}.class.should == Subscription
          end

          context "when an attribute is changed" do
            it "invokes the block when the Tuple is updated" do
              update_args = []
              tuple.on_update do |attribute, old_value, new_value|
                update_args.push [attribute, old_value, new_value]
              end

              old_value = tuple[:id]
              new_value = tuple[:id] + 1
              tuple[:id] = new_value
              update_args.should == [[tuple.relation[:id], old_value, new_value]]
            end
          end

          context "when an attribute is not changed" do
            it "does not invoke the block"
          end
        end

        describe "#delete" do
          it "releases all of its instance Relations"
        end
      end
    end
  end
end
