require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Relations
    describe BelongsTo do
      attr_reader :belongs_to
      before do
        @belongs_to = BelongsTo.new(parent_tuple, name, options)
      end

      def parent_tuple
        @parent_tuple ||= User.find("nathan")
      end

      def name
        :team
      end

      def options
        {}
      end


      describe "#operand" do
        it "is a Selection" do
          belongs_to.operand.class.should == Selection
        end

        describe ".operand" do
          it "is the #set of the class with the pluralized and classified #name" do
            belongs_to.operand.operand.should == Team.set
          end
        end

        describe ".predicate" do
          it "compares a Signal of the :id attribute with the value of the #foreign_key on the #parent_tuple" do
            belongs_to.operand.predicate.should == Team[:id].eq(parent_tuple.signal(belongs_to.foreign_key))
          end
        end
      end

      describe ":foreign_key option" do
        context "when not passed :foreign_key" do
          describe "#foreign_key" do
            it 'returns "#{name}_id"' do
              belongs_to.foreign_key.should == :team_id
            end
          end
        end

        context "when passed a :foreign_key option" do
          describe "#foreign_key" do
            def parent_tuple
              @parent_tuple ||= Profile.find("nathan_profile")
            end

            def name
              :yoga_owner
            end

            def options
              {:foreign_key => :owner_id, :class_name => :User}
            end

            it "returns the :foreign_key attribute from #options" do
              belongs_to.foreign_key.should == :owner_id
            end
          end
        end
      end

      describe ":class_name option" do
        context "when not passed a :class_name option" do
          describe "#operand" do
            it "returns a Selection whose #set is that of the class associated with the pluralized and classified #name" do
              belongs_to.operand.class.should == Selection
              belongs_to.operand.operand.should == Team.set
            end
          end
        end

        context "when passed a :class_name option" do
          def parent_tuple
            @parent_tuple ||= Profile.find("nathan_profile")
          end

          def name
            :owner
          end

          def options
            {:class_name => :User}
          end

          describe "#operand" do
            it "returns a Selection whose #set is that of the class associated with the :class_name option" do
              belongs_to.operand.class.should == Selection
              belongs_to.operand.operand.should == User.set
            end
          end
        end
      end
    end
  end
end