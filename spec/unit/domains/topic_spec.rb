require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Domains
    describe Topic do
      attr_reader :topic_class, :topic, :subject
      before do
        @subject = User.find("nathan")
        @topic_class = Class.new(Unison::Topic) do
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
        context "when the passed-in name is defined as an instance method" do
          it "causes #exposed_objects to include that method's return value" do
            topic.should respond_to(:accounts)
            topic.exposed_objects.should include(topic.accounts)
          end
        end

        context "when the passed-in name is not defined as an instance method" do
          context "when the passed-in name is defined on the #subject" do
            it "causes #exposed_objects to include the return value of #subject.photos" do
              topic.should_not respond_to(:photos)
              subject.should respond_to(:photos)
              topic.exposed_objects.should include(subject.photos)
            end
          end

          context "when the passed-in name is not defined on the #subject" do
            it "raises a NoMethodEror" do
              lambda do
                topic.i_dont_exist
              end.should raise_error(::NoMethodError)
            end
          end
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
