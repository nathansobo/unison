require "rubygems"
require "spec"
$LOAD_PATH.push("#{File.dirname(__FILE__)}/../lib")
require "unison"

# TODO: BT/NS - Remove dependency on ActiveSupport
require "test/unit"
require "active_support"

Spec::Runner.configure do |config|
  config.mock_with :rr
  
  config.before do
    Object.class_eval do
      const_set(:User, Class.new(Unison::Tuple::Base) do
        member_of Unison::Relations::Set.new(:users)
        attribute :id
        attribute :name
        attribute :hobby

        relates_to_n :photos do
          Photo.where(Photo[:user_id].eq(self[:id]))
        end

        has_one :profile
        has_many :accounts
      end)

      const_set(:Profile, Class.new(Unison::Tuple::Base) do
        member_of Unison::Relations::Set.new(:profiles)
        attribute :id
        attribute :user_id

        # belongs_to :user
      end)

      const_set(:Photo, Class.new(Unison::Tuple::Base) do
        member_of Unison::Relations::Set.new(:photos)
        attribute :id
        attribute :user_id
        attribute :name

        relates_to_1(:user) do
          User.where(User[:id].eq(self[:user_id]))
        end
      end)

      const_set(:Account, Class.new(Unison::Tuple::Base) do
        member_of Unison::Relations::Set.new(:accounts)
        attribute :id
        attribute :user_id
        attribute :name
#        belongs_to :user
      end)
    end

    users_set.insert(User.new(:id => 1, :name => "Nathan", :hobby => "Yoga"))
    users_set.insert(User.new(:id => 2, :name => "Corey", :hobby => "Drugs & Art & Burning Man"))
    users_set.insert(User.new(:id => 3, :name => "Ross", :hobby => "Manicorn"))
    profiles_set.insert(Profile.new(:id => 1, :user_id => 1))
    profiles_set.insert(Profile.new(:id => 2, :user_id => 2))
    profiles_set.insert(Profile.new(:id => 3, :user_id => 3))
    photos_set.insert(Photo.new(:id => 1, :user_id => 1, :name => "Photo 1"))
    photos_set.insert(Photo.new(:id => 2, :user_id => 1, :name => "Photo 2"))
    photos_set.insert(Photo.new(:id => 3, :user_id => 2, :name => "Photo 3"))
    accounts_set.insert(Account.new(:id => 1, :user_id => 1, :name => "Account 1"))
    accounts_set.insert(Account.new(:id => 2, :user_id => 1, :name => "Account 2"))
    accounts_set.insert(Account.new(:id => 3, :user_id => 2, :name => "Account 3"))
  end

  config.after do
    Object.class_eval do
      remove_const :User
      remove_const :Profile
      remove_const :Photo
      remove_const :Account
    end
  end
end

class Spec::ExampleGroup
  include Unison

  def users_set
    User.relation
  end

  def profiles_set
    Profile.relation
  end

  def photos_set
    Photo.relation
  end

  def accounts_set
    Account.relation
  end
end

module AddSubscriptionsMethodToRelation
  def subscriptions
    insert_subscriptions + delete_subscriptions + tuple_update_subscriptions
  end
end