require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Relations
    describe HasOne do
      attr_reader :has_one
      before do
        @has_one = HasOne.new(parent_tuple, name, options)
      end

      def parent_tuple
        @parent_tuple ||= User.find(1)
      end

      def name
        :life_goal
      end

      def options
        {}
      end

      it "is a singleton" do
        has_one.should be_singleton
      end

      describe "#operand" do
        it "is the #set of the class with the pluralized and classified #name" do
          has_one.operand.should == LifeGoal.set
        end
      end

      describe "#predicate" do
        it "compares the #foreign_key attribute with #parent_tuple.id" do
          has_one.predicate.should == LifeGoal[has_one.foreign_key].eq(parent_tuple.id)
        end
      end

      describe ":foreign_key option" do
        context "when not passed :foreign_key" do
          describe "#foreign_key" do
            it 'returns #parent_tuple.set.default_foreign_key_name' do
              has_one.foreign_key.should == parent_tuple.set.default_foreign_key_name
            end
          end
        end

        context "when passed a :foreign_key option" do
          describe "#foreign_key" do
            def name
              :profile
            end

            def options
              {:foreign_key => :owner_id}
            end

            it "returns the :foreign_key attribute from #options" do
              has_one.foreign_key.should == :owner_id
            end
          end
        end
      end

      describe ":class_name option" do
        context "when not passed a :class_name option" do
          describe "#operand" do
            it "returns the #set on the class associated with the pluralized and classified #name" do
              has_one.operand.should == LifeGoal.set
            end
          end
        end

        context "when passed a :class_name option" do
          def name
            :profile_alias
          end

          def options
            {:class_name => :Profile, :foreign_key => :owner_id}
          end

          it "uses the #set of the class with the given name as the target Relation" do
            has_one.operand.should == Profile.set
          end
        end
      end
    end
  end
end