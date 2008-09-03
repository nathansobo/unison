require File.expand_path("#{File.dirname(__FILE__)}/../unison_spec_helper")

module Unison
  describe Repository do
    describe "#fetch" do
      it "returns an array of !new? and !dirty? PrimitiveTuples" do
        tuples = origin.fetch(users_set)
        tuples.should_not be_empty
        tuples.all? do |tuple|
          !tuple.new? && !tuple.dirty?
        end.should be_true
      end

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
      context "when passed a Relation that contains PrimitiveTuples" do
        context "with PrimitiveTuples that are new?" do
          before do
            origin.connection[:photos].delete
          end

          it "inserts all new? PrimitiveTuples and sets #new? to false on them" do
            photos_set.size.should be > 1
            photos_set.all? {|tuple| tuple.new?}.should be_true

            origin.fetch(photos_set).should be_empty
            origin.push(photos_set)
            origin.fetch(photos_set).sort.should == photos_set.tuples
            photos_set.any? {|tuple| tuple.new?}.should be_false
          end
        end

        context "with PrimitiveTuples that are dirty?" do
          it "updates all dirty? PrimitiveTuples and sets #dirty? to false on them" do
            photos_set.pull(origin)
            persisted_photos = photos_set.select do |photo|
              !photo.new?
            end
            persisted_photos.size.should be > 1
            persisted_photos.each do |photo|
              photo[:name] = "#{photo[:name]} with more stuff"
            end
            persisted_photos.all? {|tuple| tuple.dirty?}.should be_true

            origin.push(photos_set)
            fetched_photos = origin.fetch(photos_set)
            origin.fetch(photos_set).sort.should == photos_set.tuples
            photos_set.any? {|tuple| tuple.dirty?}.should be_false
          end

          it "does not update PrimitiveTuples that are not dirty?" do
            photos_set.pull(origin)
            persisted_photos = photos_set.select do |photo|
              !photo.new?
            end

            table = origin.connection[:photos]
            stub(origin.connection)[:photos].returns {table}

            dont_allow(table).filter
            photos_set.any? {|photo| !photo.new?}.should be_true
            photos_set.all? {|photo| !photo.dirty?}.should be_true
            origin.push(photos_set)
          end
        end
      end

      context "when passed a Relation that contains CompositeTuples" do
        it "raises an Exception" do
          join = users_set.join(photos_set).on(users_set[:id].eq(photos_set[:user_id]))
          lambda do
            origin.push(join)
          end.should raise_error
        end
      end
    end
  end
end