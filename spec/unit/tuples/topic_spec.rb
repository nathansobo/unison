require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Tuples
    describe Topic do
      attr_reader :topic_class, :topic, :subject
      before do
        @subject = User.find("nathan")
        @topic_class = Class.new(Topic) do
          def self.name; "UserTopic"; end
          attribute_reader :id, :string
          attribute_reader :user_id, :string

          belongs_to :user
          subject :user

          expose :accounts, :team, :photos

          relates_to_many :accounts do
            subject.accounts.project(:id, :user_id, :name)
          end

          def photos
            @photos ||= subject.signal(:team_id) do |team_id|
              if team_id == "mangos"
                photos_with_camera_id
              else
                photos_without_camera_id
              end
            end
          end

          relates_to_many :photos_with_camera_id do
            subject.photos
          end

          relates_to_many :photos_without_camera_id do
            subject.photos.project(:id, :user_id, :name)
          end

        end
        @topic = topic_class.new(:user_id => subject.id)
      end

      describe ".expose" do
        it "adds the passed-in names to .exposed_method_names" do
          publicize topic_class, :exposed_method_names

          topic_class.exposed_method_names.should include(:accounts)
          topic_class.exposed_method_names.should include(:team)
        end
        
        it "causes #exposed_objects to contain the return value of each exposed method name" do
          topic.exposed_objects.should include(topic.accounts)
          topic.exposed_objects.should include(topic.team)
          topic.exposed_objects.should include(topic.photos)
        end
      end

      describe ".subject" do
        it "causes #subject to delegate to the passed-in method name" do
          topic.subject.should == topic.user
        end
      end

      describe "#subject" do
        context "when .subject was called" do
          it "delegates to the method name passed to .subject" do
            topic.subject.should == topic.user
          end
        end

        context "when .subject was not called" do
          it "raises a NoSubjectError" do
            invalid_topic_class = Class.new(Topic) do
              member_of Relations::Set.new(:topics)
              attribute_reader :id, :string
            end
            lambda do
              invalid_topic_class.new.subject
            end.should raise_error(Topic::NoSubjectError)
          end
        end
      end

      describe "#method_missing" do
        it "delegates to #subject" do
          team = subject.team
          mock.proxy(subject).team
          topic.team.should == team
        end
      end

      describe "#exposed_method_names" do
        it "delegates to .exposed_method_names on the class" do
          publicize topic_class, :exposed_method_names
          topic.exposed_method_names.should == topic_class.exposed_method_names
        end
      end

      describe "#exposed_objects" do
        it "returns the results of sending all #exposed_method_names" do
          topic.exposed_objects.should == topic.exposed_method_names.map do |method_name|
            topic.send(method_name)
          end
        end
      end

      describe "#exposed_relations" do
        it "returns only those #exposed_objects that are subclasses of Relations::Relation" do
          topic.exposed_objects.any? {|object| object.is_a?(Signals::Signal)}
          exposed_relations = topic.exposed_relations
          exposed_relations.should_not be_empty
          exposed_relations.each do |object|
            object.class.ancestors.should include(Relations::Relation)
          end
        end
      end

      describe "#exposed_signals" do
        it "returns only those #exposed_objects that are subclasses of Signals::Signal" do
          topic.exposed_objects.any? {|object| object.is_a?(Relations::Relation)}
          exposed_signals = topic.exposed_signals
          exposed_signals.should_not be_empty
          exposed_signals.each do |object|
            object.class.ancestors.should include(Signals::Signal)
          end
        end
      end

      context "when #retained?" do
        attr_reader :retainer
        before do
          @retainer = Object.new
          topic.retain_with(retainer)
        end

        it "retains all exposed Objects" do
          topic.exposed_objects.each do |exposed_object|
            exposed_object.should be_retained_by(topic)
          end
        end

        it "sets the :hash_representation Attribute value to a Hash (type => id => attributes) of the exposed objects" do
          subject.team_id.should == "chargers"
          
          topic[:hash_representation].should == {
              "Account" => {
                "nathan_pivotal_account" => topic.accounts.find("nathan_pivotal_account").hash_representation.stringify_keys,
                "nathan_account_2" => topic.accounts.find("nathan_account_2").hash_representation.stringify_keys,
              },
              "Team" => {
                "chargers" => Team.find("chargers").hash_representation.stringify_keys,
              },
              "Photo" => {
                "nathan_photo_1" => topic.photos_without_camera_id.find("nathan_photo_1").hash_representation.stringify_keys,
                "nathan_photo_2" => topic.photos_without_camera_id.find("nathan_photo_2").hash_representation.stringify_keys
              }
            }
        end

        describe "#json_representation" do
          it "returns #hash_representation.to_json" do
            JSON.parse(topic.json_representation).should == JSON.parse(topic.hash_representation.to_json)
          end
        end

        context "when an event is triggered on a directly exposed Relation" do
          context "when an insert event is triggered in an exposed Relation" do
            it "inserts the Tuple's #attributes into the memoized #hash_representation" do
              representation = topic.hash_representation
              representation["Account"]["nathan_inserted_account"].should be_nil
              inserted_account = Account.create(:id => "nathan_inserted_account", :user_id => "nathan", :name => "inserted account")
              representation["Account"]["nathan_inserted_account"].should == topic.accounts.find("nathan_inserted_account").hash_representation.stringify_keys
            end

            it "triggers the on_update event for the :hash_representation PrimitiveAttribute" do
              update_args = []
              topic.on_update(retainer) do |attribute, old_value, new_value|
                update_args.push [attribute, old_value, new_value]
              end

              inserted_account = Account.create(:id => "nathan_inserted_account", :user_id => "nathan", :name => "inserted account")
              update_args.should == [[topic.set[:hash_representation], topic.hash_representation, topic.hash_representation]]
            end
          end

          context "when a delete event is triggered in an exposed Relation" do
            it "removes the Tuple's #attributes from the memoized #hash_representation" do
              representation = topic.hash_representation
              representation["Account"]["nathan_pivotal_account"].should_not be_nil

              Account.find("nathan_pivotal_account").delete
              representation["Account"].should_not have_key("nathan_pivotal_account")
            end

            it "triggers the on_update event for the :hash_representation PrimitiveAttribute" do
              update_args = []
              topic.on_update(retainer) do |attribute, old_value, new_value|
                update_args.push [attribute, old_value, new_value]
              end

              Account.find("nathan_pivotal_account").delete
              update_args.should == [ [topic.set[:hash_representation], topic.hash_representation, topic.hash_representation] ]
            end
          end

          context "when a tuple_update event is triggered in an exposed Relation" do
            it "updates the changed Tuple's #attributes in the memoized #hash_representation" do
              representation = topic.hash_representation
              account = Account.find("nathan_pivotal_account")
              new_value = "#{account.name} with more baggage"

              representation["Account"]["nathan_pivotal_account"]["name"].should_not == new_value
              account.name = new_value
              representation["Account"]["nathan_pivotal_account"]["name"].should == new_value
            end

            it "triggers the on_update event for the :hash_representation PrimitiveAttribute" do
              representation = topic.hash_representation
              account = Account.find("nathan_pivotal_account")
              new_value = "#{account.name} with more baggage"

              update_args = []
              topic.on_update(retainer) do |attribute, old_value, new_value|
                update_args.push [attribute, old_value, new_value]
              end

              account.name = new_value

              update_args.should == [[topic.set[:hash_representation], topic.hash_representation, topic.hash_representation]]
            end
          end
        end

        context "when an event is triggered on a Relation that is the #value of an exposed Signal" do
          before do
            subject.team_id.should == "chargers"
            topic.photos.value.should == topic.photos_without_camera_id
          end

          context "when an insert event is triggered on a Relational that is the #value of an exposed Signal" do
            it "inserts the Tuple's #attributes into the memoized #hash_representation" do
              representation = topic.hash_representation
              representation["Photo"]["nathan_photo_3"].should be_nil
              inserted_photo = Photo.create(:id => "nathan_photo_3", :user_id => "nathan", :name => "another photo", :camera_id => "minolta_xd_11")
              representation["Photo"]["nathan_photo_3"].should == topic.photos_without_camera_id.find("nathan_photo_3").hash_representation.stringify_keys
            end

            it "triggers the on_update event for the :hash_representation PrimitiveAttribute" # do
#              update_args = []
#              topic.on_update(retainer) do |attribute, old_value, new_value|
#                update_args.push [attribute, old_value, new_value]
#              end
#
#              inserted_account = Photo.create(:id => "nathan_inserted_account", :user_id => "nathan", :name => "inserted account")
#              update_args.should == [[topic.set[:hash_representation], topic.hash_representation, topic.hash_representation]]
#            end
          end
        end


        context "after last release" do
          it "no longer memoizes the :hash_representation PrimitiveAttribute" do
            dont_allow(topic).create_hash_representation
            memoized_hash_representation = topic[:hash_representation]
            topic[:hash_representation].should equal(memoized_hash_representation)
            
            topic.release_from(retainer)
            topic.should_not be_retained

            mock.proxy(topic).create_hash_representation.twice
            topic[:hash_representation].should == memoized_hash_representation
            topic[:hash_representation].should_not equal(memoized_hash_representation)
          end
        end
      end

      context "when not #retained?" do
        describe "#hash_representation" do
          it "returns a class name => id => attributes Hash of the exposed objects" do
            topic.hash_representation.should == {
              "Account" => {
                "nathan_pivotal_account" => topic.accounts.find("nathan_pivotal_account").hash_representation.stringify_keys,
                "nathan_account_2" => topic.accounts.find("nathan_account_2").hash_representation.stringify_keys,
              },
              "Team" => {
                "chargers" => Team.find("chargers").hash_representation.stringify_keys,
              },
              "Photo" => {
                "nathan_photo_1" => topic.photos_without_camera_id.find("nathan_photo_1").hash_representation.stringify_keys,
                "nathan_photo_2" => topic.photos_without_camera_id.find("nathan_photo_2").hash_representation.stringify_keys
              }
            }
          end
        end

        describe "#json_representation" do
          it "returns #hash_representation.to_json" do
            JSON.parse(topic.json_representation).should == JSON.parse(topic.hash_representation.to_json)
          end
        end
      end
    end
  end
end
