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
          projection = users_set \
                         .join(photos_set) \
                           .on(users_set[:id].eq(photos_set[:user_id])) \
                         .project(photos_set)
          
          origin.fetch(projection).should == origin.fetch(photos_set)
        end
      end

      context "when passed an InnerJoin" do
        it "raises a NotImplementedError" do
          join = users_set.join(photos_set).on(users_set[:id].eq(photos_set[:user_id]))
          lambda do
            origin.fetch(join)
          end.should raise_error(NotImplementedError)
        end
      end
    end

    describe "#push" do
      context "when passed a Relation other than InnerJoin" do
        it "inserts all new? PrimitiveTuples and sets #new? to false on them" do
          selection = photos_set.where(photos_set[:user_id].eq(1))
          selection.size.should be > 1
          selection.all? {|tuple| tuple.new?}.should be_true

          origin.fetch(selection).should be_empty
          origin.push(selection)
          origin.fetch(selection).should == selection.tuples
          selection.any? {|tuple| tuple.new?}.should be_false
        end
      end

      context "when passed an InnerJoin" do
        it "raises a NotImplementedError" do
          join = users_set.join(photos_set).on(users_set[:id].eq(photos_set[:user_id]))
          lambda do
            origin.push(join)
          end.should raise_error(NotImplementedError)
        end
      end
    end
  end
end