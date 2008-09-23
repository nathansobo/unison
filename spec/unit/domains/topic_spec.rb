require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Tuples
    describe Topic do
      attr_reader :topic_class, :topic, :subject
      before do
        @subject = User.find("nathan")
        @topic_class = Class.new(Unison::Topic) do
          member_of Relations::Set.new(:topics)
          attribute_reader :id, :string

          expose :accounts, :photos
          relates_to_many :accounts do
            subject.accounts
          end
        end
        @topic = topic_class.new(subject)
      end

      describe ".expose" do
        it "adds the passed-in names to .exposed_method_names" do
          publicize topic_class, :exposed_method_names

          topic_class.exposed_method_names.should include(:accounts)
          topic_class.exposed_method_names.should include(:photos)
        end
      end

      describe ".expose" do
        it "causes #exposed_objects to contain the return value of each exposed method name" do
          topic.exposed_objects.should include(topic.accounts)
          topic.exposed_objects.should include(topic.photos)
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
        end

        it "retains all exposed Relations" do
          publicize topic_class, :exposed_method_names

          topic.retain_with(retainer)
          topic.exposed_objects.each do |exposed_object|
            exposed_object.should be_retained_by(topic)
          end
        end
      end

      context "when not #retained?" do
        
      end
    end
  end
end
