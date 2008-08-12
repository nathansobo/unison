require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

module Unison
  describe Repository do
    describe "#fetch" do
      it "returns an array of Relation#tuple_class instances based on the result of a query using Relation#to_sql" do
        origin.fetch(users_set).should == [
          users_set.tuple_class.new(:id => 11, :name => "Buffington", :hobby => "Bots"),
          users_set.tuple_class.new(:id => 12, :name => "Keefa", :hobby => "Begging")
        ]
      end
    end

    describe "#push" do
      
    end
  end
end