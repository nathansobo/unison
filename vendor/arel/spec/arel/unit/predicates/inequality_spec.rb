require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')

module Arel
  describe Inequality do
    before do
      @relation1 = Table.new(:users)
      @relation2 = Table.new(:photos)
      @attribute1 = @relation1[:id]
      @attribute2 = @relation2[:user_id]
    end
  
    describe '==' do 
      it "obtains if attribute1 and attribute2 are identical" do
        Inequality.new(@attribute1, @attribute2).should == Inequality.new(@attribute1, @attribute2)
        Inequality.new(@attribute1, @attribute2).should_not == Inequality.new(@attribute1, @attribute1)
      end
    
      it "obtains if the concrete type of the predicates are identical" do
        Inequality.new(@attribute1, @attribute2).should_not == Binary.new(@attribute1, @attribute2)
      end
    
      it "is commutative on the attributes" do
        Inequality.new(@attribute1, @attribute2).should == Inequality.new(@attribute2, @attribute1)
      end
    end
    
    describe '#to_sql' do
      describe 'when relating to a non-nil value' do
        it "manufactures an inequality predicate" do
          Inequality.new(@attribute1, @attribute2).to_sql.should be_like("
            `users`.`id` <> `photos`.`user_id`
          ")
        end
      end
      
      describe 'when relation to a nil value' do
        before do
          @nil = nil
        end
        
        it "manufactures an is not null predicate" do
          Inequality.new(@attribute1, @nil).to_sql.should be_like("
            `users`.`id` IS NOT NULL
          ")
        end
      end
    end
  end
end