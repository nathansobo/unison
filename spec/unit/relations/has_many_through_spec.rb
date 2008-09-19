require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Relations
    describe HasManyThrough do
      attr_reader :has_many_through
      before do
        @has_many_through = HasManyThrough.new(parent_tuple, name, options)
        publicize has_many_through, :target_relation
      end

      def parent_tuple
        @parent_tuple ||= User.find("nathan")
      end

      def name
        :cameras
      end

      def options
        {:through => :photos}
      end

      describe "#projected_set" do
        it "returns the #target_relation" do
          has_many_through.projected_set.should == Camera.set
          has_many_through.projected_set.should == has_many_through.target_relation
        end
      end

      context "when the through Relation is the owner of the :foreign_key" do
        before do
          Photo[:camera_id].should_not be_nil
        end

        describe "#operand" do
          it "returns an InnerJoin of the #through_relation and the #target_relation on #through_relation[#foreign_key].eq(#target_relation[:id])" do
            has_many_through.operand.should == parent_tuple.photos.join(Camera.set).on(parent_tuple.photos[:camera_id].eq(Camera[:id]))
          end
        end

        describe ":foreign_key option" do
          def name
            :users
          end

          def options
            {:through => :friendships_to_me, :foreign_key => :from_id}
          end

          describe "#foreign_key" do
            it "returns the :foreign_key from #options" do
              has_many_through.foreign_key.should == :from_id
            end
          end
        end
      end

      context "when the target Relation is the owner of the :foreign_key" do
        def parent_tuple
          @parent_tuple ||= Team.find("mangos")
        end

        def name
          :photos
        end

        def options
          {:through => :users}
        end

        describe "#operand" do
          it "is the InnerJoin of the #through_relation and the #target_relation on #through_relation[:id].eq(#target_relation[#foreign_key])" do
            has_many_through.operand.should == parent_tuple.users.join(Photo.set).on(parent_tuple.users[:id].eq(Photo[:user_id]))
          end
        end

        describe ":foreign_key option" do
          def parent_tuple
            @parent_tuple ||= Profile.find("nathan_profile")
          end

          def name
            :friendships_to_me
          end

          def options
            {:through => :owner, :foreign_key => :to_id, :class_name => :Friendship}
          end

          describe "#foreign_key" do
            it "returns the :foreign_key from #options" do
              has_many_through.foreign_key.should == :to_id
            end
          end
        end
      end

      describe ":class_name option" do
        context "when not passed a :class_name option" do
          describe "#target_relation" do
            it "returns the #set on the class associated with the pluralized and classified #name" do
              has_many_through.target_relation.should == Camera.set
            end
          end
        end

        context "when passed a :class_name option" do
          def name
            :fans
          end

          def options
            {:through => :friendships_to_me, :class_name => :User, :foreign_key => :from_id}
          end

          describe "#target_relation" do
            it "returns the #set on the class associated with options[:class_name]" do
              has_many_through.target_relation.should == User.set
            end
          end
        end
      end

      context "when passed a :through relation that is #nil?" do
        def parent_tuple
          @parent_tuple ||= Profile.find("corey_profile")
        end

        def name
          :yoga_photos
        end

        def options
          {:through => :yoga_owner, :class_name => :Photo}
        end

        it "returns an empty Relation" do
          yogaless_profile = Profile.find("corey_profile")
          yogaless_profile.yoga_owner.should be_nil
          yogaless_profile.yoga_photos.should == []
        end
      end
    end
  end
end