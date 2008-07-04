require "#{File.dirname(__FILE__)}/../spec_helper"

module Unison
  describe Mailbox do
    attr_reader :mailbox
    before do
      @mailbox = Mailbox.new
    end

    describe "#subscribe" do
      it "given a Relation and an event type, will subscribe to the relation and fire the given block when those events are taken" do
        pending
        mailbox.freeze
        subscription_1_creates = []
        subscription_2_creates = []

        mailbox.subscribe(photos_set, :create) do |created|
          subscription_1_creates.push(created)
        end
        mailbox.subscribe(photos_set, :create) do |created|
          subscription_2_creates.push(created)
        end

        Photo.create(:id => 100, :user_id => 1, :name => "Caught in the act!")
        mailbox.events.length.should == 1
        Photo.create(:id => 101, :user_id => 1, :name => "Here he is sad.")
        mailbox.events.length.should == 2

        subscription_1_creates.should be_empty
        subscription_2_creates.should be_empty

        mailbox.take

        subscription_1_creates.should have_length(1)
        subscription_2_creates.should have_length(1)

        mailbox.take

        subscription_1_creates.should have_length(2)
        subscription_2_creates.should have_length(2)
      end
    end
  end
end