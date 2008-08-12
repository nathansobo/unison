require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

module Unison
  describe Repository do
    describe "#fetch" do

      context "when passed a Set" do
        it "returns an array of Relation#tuple_class instances based on the result of a query using Relation#to_sql" do
          origin.fetch(users_set).should == [
            User.new(:id => 11, :name => "Buffington", :hobby => "Bots"),
              User.new(:id => 12, :name => "Keefa", :hobby => "Begging")
          ]
        end
      end

      context "when passed a Selection" do
        it "returns an array of Relation#tuple_class instances based on the result of a query using Relation#to_sql" do
          selection = users_set.where(users_set[:name].eq("Buffington"))
          origin.fetch(selection).should == [User.new(:id => 11, :name => "Buffington", :hobby => "Bots")]
        end
      end

      context "when passed a Projection" do
        it "returns an array of Relation#tuple_class instances based on the result of a query using Relation#to_sql" do
          
        end
      end
    end
  end
end