require "#{File.dirname(__FILE__)}/../spec_helper"

module Unison
  describe "A Tuple with a has-many relation" do
    it "receives create events on the relation's operand in its #mailbox" do
      pending
      user = User.find(1)
      user.mailbox.freeze
      photo_count = user.photos.size
      photos_set.insert(Photo.new(:id => 99, :user_id => 1, :name => "Another photo"))
      user.photos.size.should == photo_count
      user.mailbox.take
      user.photos.size.should == photo_count + 1
    end
  end
end