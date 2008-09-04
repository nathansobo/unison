require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Relations
    describe CompositeRelation do
      describe "#subscribed_to?" do
        context "when #subscriptions contains a Subscription that is in the passed in SubscriptionNode" do
          it "returns true" do

            relation = users_set.where(User[:id].eq(1))
            publicize relation, :subscriptions
            publicize users_set, :insert_subscription_node

            relation.retained_by(Object.new)
            relation.subscriptions.should_not be_empty

            relation.should be_subscribed_to(users_set.insert_subscription_node)
          end
        end
      end
    end
  end
end
