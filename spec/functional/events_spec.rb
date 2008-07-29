require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

module Unison
  describe "A Tuple with a has-many relation" do
    it "receives create events on the relation's operand" do
      pending do
        user = User.find(1)
        user.mailbox.freeze
        user.mailbox.events.size.should == 0
        user.photos.read.should_not be_empty

        photo = photos_set.insert(Photo.new(:id => 99, :user_id => 1, :name => "Another photo"))

        user.photos.read.should_not include(photo)
        user.mailbox.take
        user.photos.read.should include(photo)
      end
    end
  end
end