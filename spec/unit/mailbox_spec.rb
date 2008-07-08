require "#{File.dirname(__FILE__)}/../spec_helper"

describe Unison::Mailbox do
  attr_reader :mailbox
  before do
    @mailbox = Unison::Mailbox.new
  end

  describe "#publish" do
    context "when the Mailbox is #frozen?" do
      before do
        mailbox.freeze
        mailbox.should be_frozen
      end

      it "pushes the given event to the #events array" do
        event = Event.new(users_set, :insert, User.find(1))
        mailbox.publish(event)
        mailbox.events.should == [event]
      end
    end

    context "when the Mailbox is not #frozen?" do
      include Unison

      before do
        mailbox.should_not be_frozen
      end

      it "executes the events immediately" do
        callback_argument = nil
        mailbox.subscribe(users_set, :insert) do |event|
          callback_argument = event
        end
        user = User.find(1)
        mailbox.publish(Unison::Event.new(users_set, :insert, User.find(1)))
        callback_argument.should == user
      end
    end
  end

  describe "#take" do
    it "processes one event from the events array, calling the registered procedures" do
      mailbox.freeze
      inserts = []
      object = User.find(1)
      mailbox.subscribe(photos_set, :insert) do |inserted|
        inserts.push(inserted)
      end
      mailbox.publish(Event.new(users_set, :insert, object))
      mailbox.events.length.should == 1
      mailbox.take
      mailbox.events.should be_empty
    end
  end

  describe "#subscribe" do
    it "given a Relation and an event type, will subscribe to the relation and fire the given block when those events are taken" do
      mailbox.freeze
      subscription_1_inserts = []
      subscription_2_inserts = []

      mailbox.subscribe(photos_set, :insert) do |inserted|
        subscription_1_inserts.push(inserted)
      end
      mailbox.subscribe(photos_set, :insert) do |inserted|
        subscription_2_inserts.push(inserted)
      end

      Photo.create(:id => 100, :user_id => 1, :name => "Caught in the act!")
      mailbox.events.length.should == 1
      Photo.create(:id => 101, :user_id => 1, :name => "Here he is sad.")
      mailbox.events.length.should == 2

      subscription_1_inserts.should be_empty
      subscription_2_inserts.should be_empty

      mailbox.take

      subscription_1_inserts.length.should == 1
      subscription_2_inserts.length.should == 1

      mailbox.take

      subscription_1_inserts.length.should == 2
      subscription_2_inserts.length.should == 2
    end
  end
end