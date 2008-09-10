require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Relations
    describe HasMany do
      attr_reader :has_many
      before do
        @has_many = HasMany.new(parent_tuple, name, options)
      end

      def parent_tuple
        @parent_tuple ||= User.find("nathan")
      end

      def name
        :photos
      end

      def options
        {}
      end

      it "is not a singleton" do
        has_many.should_not be_singleton
      end

      describe "#operand" do
        it "is the #set of the class with the pluralized and classified #name" do
          has_many.operand.should == Photo.set
        end
      end

      describe "#predicate" do
        it "compares the #foreign_key attribute with #parent_tuple.id" do
          has_many.predicate.should == Photo[has_many.foreign_key].eq(parent_tuple.id)
        end
      end

      describe ":foreign_key option" do
        context "when not passed :foreign_key" do
          describe "#foreign_key" do
            it 'returns #parent_tuple.set.default_foreign_key_name' do
              has_many.foreign_key.should == parent_tuple.set.default_foreign_key_name
            end
          end
        end

        context "when passed a :foreign_key option" do
          describe "#foreign_key" do
            def name
              :friendships_to_me
            end

            def options
              {:foreign_key => :to_id, :class_name => :Friendship}
            end

            it "returns the :foreign_key attribute from #options" do
              has_many.foreign_key.should == :to_id
            end
          end
        end
      end

      describe ":class_name option" do
        context "when not passed a :class_name option" do
          describe "#operand" do
            it "returns the #set on the class associated with the pluralized and classified #name" do
              has_many.operand.should == Photo.set
            end
          end
        end

        context "when passed a :class_name option" do
          def name
            :friendships_to_me
          end

          def options
            {:foreign_key => :to_id, :class_name => :Friendship}
          end

          it "uses the #set of the class with the given name as the target Relation" do
            has_many.operand.should == Friendship.set
          end
        end
      end

      describe "#create" do
        it "creates an instance of the #operand.tuple_class with its #foreign_key set to the parent_tuple.id" do
          name = "Photo 100"
          photo = has_many.create(:id => 100, :name => name)
          Photo.set.should include(photo)
          photo.class.should == Photo
          photo.user_id.should == parent_tuple.id
          photo.name.should == name
        end
      end
    end
  end
end