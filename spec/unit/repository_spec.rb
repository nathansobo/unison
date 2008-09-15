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
            User.new(:id => "buffington", :name => "Buffington", :hobby => "Bots", :team_id => "mangos"),
              User.new(:id => "keefa", :name => "Keefa", :hobby => "Begging", :team_id => "chargers")
          ]
        end
      end

      context "when passed a Selection" do
        it "returns an array of Relation#tuple_class instances based on the result of a query using Relation#to_sql" do
          selection = users_set.where(users_set[:name].eq("Buffington"))
          origin.fetch(selection).should == [User.new(:id => "buffington", :name => "Buffington", :hobby => "Bots", :team_id => "mangos")]
        end
      end

      context "when passed a Projection" do
        it "returns an array of Relation#tuple_class instances based on the result of a query using Relation#to_sql" do
          projection = users_set \
            .join(photos_set) \
            .on(users_set[:id].eq(photos_set[:user_id])) \
            .project(photos_set)

          origin.fetch(projection).should have_the_same_elements_as(origin.fetch(photos_set))
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
      context "when passed a PrimitiveTuple" do
        attr_reader :tuple
        context "when PrimitiveTuple is new?" do
          before do
            origin.connection[:photos].delete
            @tuple = photos_set.tuples.first
            tuple.should be_new
          end

          it "inserts PrimitiveTuple and sets #new? to false" do
            origin.fetch(photos_set).should be_empty
            origin.push(tuple)
            origin.fetch(photos_set).should == [tuple]
            tuple.should_not be_new
          end
        end

        context "when PrimitiveTuple is not new? and dirty?" do
          before do
            photos_set.pull
            photos_set.push
            @tuple = photos_set.tuples.first
            tuple.should_not be_new
            tuple[:name] = "#{tuple[:name]} with Holy Crap"
            tuple.should be_dirty
          end

          it "updates the PrimitiveTuple and sets #dirty? to false" do
            origin.push(tuple)
            origin.fetch(photos_set).sort.should == photos_set.sort
            tuple.should_not be_dirty
          end
        end

        context "when PrimitiveTuple is not new? and not dirty?" do
          before do
            photos_set.pull
            photos_set.push
            @tuple = photos_set.tuples.first
            tuple.should_not be_new
            tuple.should_not be_dirty
          end

          it "does not insert or update the PrimitiveTuple" do
            table = origin.connection[:photos]
            stub(origin.connection)[:photos].returns {table}

            dont_allow(table).filter
            origin.push(tuple)
          end
        end
      end

      context "when passed a Relation that contains PrimitiveTuples" do
        context "when the Relation is a singleton" do
          attr_reader :relation, :tuple

          context "when PrimitiveTuple is new?" do
            before do
              origin.connection[:photos].delete
              @relation = photos_set.where(Photo[:id].eq("nathan_photo_1")).singleton
              @tuple = relation.tuple
              relation.tuple.should be_new
            end

            it "inserts PrimitiveTuple and sets #new? to false" do
              origin.fetch(relation).should be_empty
              origin.push(relation)
              origin.fetch(relation).sort.should == relation.tuples
              relation.tuple.should_not be_new
            end
          end

          context "when PrimitiveTuple is not new? and dirty?" do
            before do
              @relation = photos_set.where(Photo[:id].eq("nathan_photo_1")).singleton
              @tuple = relation.tuple
              relation.push
              tuple.should_not be_new
              tuple[:name] = "#{tuple[:name]} with Holy Crap"
              tuple.should be_dirty
            end

            it "updates the PrimitiveTuple and sets #dirty? to false" do
              origin.push(relation)
              fetched_photos = origin.fetch(relation)
              origin.fetch(relation).sort.should == relation.tuples
              relation.tuple.should_not be_dirty
            end
          end

          context "when PrimitiveTuple is not new? and not dirty?" do
            before do
              @relation = photos_set.where(Photo[:id].eq("nathan_photo_1")).singleton
              @tuple = relation.tuple
              relation.push
              tuple.should_not be_new
              tuple.should_not be_dirty
            end
            
            it "does not insert or update the PrimitiveTuple" do
              table = origin.connection[:photos]
              stub(origin.connection)[:photos].returns {table}

              dont_allow(table).filter
              origin.push(relation)
            end
          end
        end

        context "when the Relation is not a singleton" do
          context "with PrimitiveTuples that are new?" do
            before do
              origin.connection[:photos].delete
            end

            it "inserts all new? PrimitiveTuples and sets #new? to false on them" do
              photos_set.size.should be > 1
              photos_set.all? {|tuple| tuple.new?}.should be_true

              origin.fetch(photos_set).should be_empty
              origin.push(photos_set)
              origin.fetch(photos_set).sort_by(&:id).should == photos_set.tuples.sort_by(&:id)
              photos_set.any? {|tuple| tuple.new?}.should be_false
            end
          end

          context "with PrimitiveTuples that are dirty?" do
            it "updates all dirty? PrimitiveTuples and sets #dirty? to false on them" do
              photos_set.pull(origin)
              pushed_photos = photos_set.select do |photo|
                !photo.new?
              end
              pushed_photos.size.should be > 1
              pushed_photos.each do |photo|
                photo[:name] = "#{photo[:name]} with more stuff"
              end
              pushed_photos.all? {|tuple| tuple.dirty?}.should be_true

              origin.push(photos_set)
              fetched_photos = origin.fetch(photos_set)
              origin.fetch(photos_set).sort_by(&:id).should == photos_set.tuples.sort_by(&:id)
              photos_set.any? {|tuple| tuple.dirty?}.should be_false
            end

            it "does not update PrimitiveTuples that are not dirty?" do
              photos_set.pull(origin)
              pushed_photos = photos_set.select do |photo|
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
      end

      context "when passed a Relation that contains CompositeTuples" do
        it "raises an Exception" do
          join = users_set.join(photos_set).on(users_set[:id].eq(photos_set[:user_id]))
          lambda do
            origin.push(join)
          end.should raise_error
        end
      end

      context "when passed an InnerJoin" do
        it "raises an ArgumentError" do
          join = users_set.join(photos_set).on(users_set[:id].eq(photos_set[:user_id]))
          lambda do
            origin.push(join)
          end.should raise_error(NotImplementedError)
        end
      end

      context "when passed a CompositeTuple" do
        it "raises a NotImplementedError" do
          tuple = CompositeTuple.new(users_set.tuples.first)
          lambda do
            origin.push(tuple)
          end.should raise_error(NotImplementedError)
        end
      end
    end
  end
end