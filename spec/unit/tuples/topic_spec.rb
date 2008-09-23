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

          expose :accounts, :photos
          relates_to_many :accounts do
            subject.accounts
          end
        end
        @topic = topic_class.new(:user_id => subject.id)
      end

      describe ".expose" do
        it "adds the passed-in names to .exposed_method_names" do
          publicize topic_class, :exposed_method_names

          topic_class.exposed_method_names.should include(:accounts)
          topic_class.exposed_method_names.should include(:photos)
        end
        
        it "causes #exposed_objects to contain the return value of each exposed method name" do
          topic.exposed_objects.should include(topic.accounts)
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
          photos = subject.photos
          mock.proxy(subject).photos
          topic.photos.should == photos
        end
      end

      context "when #retained?" do
        attr_reader :retainer
        before do
          @retainer = Object.new
          topic.retain_with(retainer)
        end

        it "retains all exposed Relations" do
          publicize topic_class, :exposed_method_names
          topic.exposed_objects.each do |exposed_object|
            exposed_object.should be_retained_by(topic)
          end
        end

        describe "#hash_representation" do
          it "returns a class name => id => attributes Hash of the exposed objects" do
            topic.hash_representation.should == {
              "Account" => {
                "nathan_pivotal_account" => Account.find("nathan_pivotal_account").attributes.stringify_keys,
                "nathan_account_2" => Account.find("nathan_account_2").attributes.stringify_keys,
              },
              "Photo" => {
                "nathan_photo_1" => Photo.find("nathan_photo_1").attributes.stringify_keys,
                "nathan_photo_2" => Photo.find("nathan_photo_2").attributes.stringify_keys
              }
            }
          end

          context "when an insert event is triggered in an exposed Relation" do
            it "inserts the Tuple's #attributes into the memoized #hash_representation" do
              representation = topic.hash_representation
              representation["Account"]["nathan_inserted_account"].should be_nil

              inserted_account = Account.create(:id => "nathan_inserted_account", :user_id => "nathan", :name => "inserted account")
              representation["Account"]["nathan_inserted_account"].should == inserted_account.attributes.stringify_keys
            end
          end

          context "when a delete event is triggered in an exposed Relation" do
            it "removes the Tuple's #attributes from the memoized #hash_representation" do
              representation = topic.hash_representation
              representation["Account"]["nathan_pivotal_account"].should_not be_nil

              Account.find("nathan_pivotal_account").delete
              representation["Account"].should_not have_key("nathan_pivotal_account")
            end
          end

          context "when a tuple_update event is triggered in an exposed Relation" do
            it "updates the changed Tuple's #attributes in the memoized #hash_representation" do
              representation = topic.hash_representation

              account = Account.find("nathan_pivotal_account")
              old_value = account.name
              new_value = "#{old_value} with more baggage"
              representation["Account"]["nathan_pivotal_account"]["name"].should == old_value

              account.name = new_value
              representation["Account"]["nathan_pivotal_account"]["name"].should == new_value
            end
          end          
        end
      end

      context "when not #retained?" do
        describe "#hash_representation" do
          it "returns a class name => id => attributes Hash of the exposed objects" do
            topic.hash_representation.should == {
              "Account" => {
                "nathan_pivotal_account" => Account.find("nathan_pivotal_account").attributes.stringify_keys,
                "nathan_account_2" => Account.find("nathan_account_2").attributes.stringify_keys,
              },
              "Photo" => {
                "nathan_photo_1" => Photo.find("nathan_photo_1").attributes.stringify_keys,
                "nathan_photo_2" => Photo.find("nathan_photo_2").attributes.stringify_keys
              }
            }
          end
        end
      end
    end
  end
end
