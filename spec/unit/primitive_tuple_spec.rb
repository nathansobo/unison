require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

module Unison
  module PrimitiveTuple
    describe Base do
      attr_reader :tuple_class, :tuple

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
            mock.proxy(User.relation).attribute(:name, :string)
            User.attribute(:name, :string)
          end
        end

        describe ".attribute_reader" do
          it "creates an attribute on the .relation" do
            mock.proxy(User.relation).attribute(:name, :string)
            User.attribute_reader(:name, :string)
          end

          it "adds a reader method to the Tuple" do
            User.attribute_reader(:nick_name, :string)
            user = User.new(:nick_name => "Bob")
            user.nick_name.should == "Bob"
          end

          it "does not add a writer method to the Tuple" do
            User.attribute_reader(:name, :string)
            user = User.new
            user.should_not respond_to(:name=)
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

          it "creates a Selection on the target Set where the foreign key matches id" do
            user.accounts.should_not be_empty
            user.accounts.should == accounts_set.where(accounts_set[:user_id].eq(user[:id]))
          end

          it "does not create a singleton Selection" do
            user.accounts.should_not be_singleton
          end
        end

        describe ".has_one" do
          attr_reader :user
          before do
            @user = User.find(1)
          end

          it "creates a singleton Selection on the target Set where the foreign key matches id" do
            user.profile.should be_singleton
            user.profile.should == Profile.find(1)
          end
        end

        describe ".belongs_to" do
          attr_reader :profile, :user
          before do
            @profile = Profile.find(1)
            @user = User.find(1)
          end

          it "creates a singleton Selection on the target Set where the target's id matches the instance's foreign key" do
            profile.user.should be_singleton
            profile.user.should == user
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
          it "assigns a hash of attribute-value pairs corresponding to its relation" do
            tuple = User.new(:id => 1, :name => "Nathan")
            tuple[:id].should == 1
            tuple[:name].should == "Nathan"
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
