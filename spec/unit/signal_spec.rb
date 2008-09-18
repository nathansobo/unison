require File.expand_path("#{File.dirname(__FILE__)}/../unison_spec_helper")

module Unison
  describe Signal do
    attr_reader :user, :attribute, :signal
    before do
      @user = User.find("nathan")
      @attribute = users_set[:name]
      @signal = user.signal(attribute)
    end

    describe "#to_arel" do
      it "delegates to #value.to_arel" do
        signal.to_arel.should == user[:name].to_arel
      end
    end
  end
end
