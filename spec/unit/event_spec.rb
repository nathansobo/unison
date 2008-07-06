require "#{File.dirname(__FILE__)}/../spec_helper"

describe Unison::Event do
  attr_reader :relation, :object, :event
  before do
    @relation = users_set
    @object = User.find(1)
    @event = Event.new(relation, :insert, object)
  end

  describe "#initialize" do
    it "sets the #relation, #type and #object" do
      event.relation.should == relation
      event.type.should == :insert
      event.object.should == object
    end
  end
end