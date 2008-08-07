require "rubygems"
require "spec"
dir = File.dirname(__FILE__)
$LOAD_PATH.push("#{dir}/../lib")
require "unison"

# TODO: BT/NS - Remove dependency on ActiveSupport
require "test/unit"
require "active_support"
require "#{dir}/spec_helpers/be_like"

Spec::Runner.configure do |config|
  config.mock_with :rr
  
  config.before do
    Object.class_eval do
      const_set(:User, Class.new(Unison::PrimitiveTuple::Base) do
        member_of Unison::Relations::Set.new(:users)
        
        attribute_accessor :id, :integer
        attribute_accessor :name, :string
        attribute_accessor :hobby, :string

        has_many :photos

        has_one :profile, :foreign_key => :owner_id
        has_one :profile_alias, :class_name => :Profile, :foreign_key => :owner_id

        has_one :life_goal
        has_many :accounts
        has_one :active_account, :class_name => :Account do |account|
          accounts.where(Account.active?)
        end
        has_many :active_accounts, :class_name => :Account do |accounts|
          accounts.where(Account.active?)
        end

        has_many :to_friendships, :foreign_key => :to_id, :class_name => :Friendship
        has_many :from_friendships, :foreign_key => :from_id, :class_name => :Friendship
      end)

      const_set(:LifeGoal, Class.new(Unison::PrimitiveTuple::Base) do
        member_of Unison::Relations::Set.new(:life_goals)
        attribute_accessor :id, :integer
        attribute_accessor :user_id, :integer

        belongs_to :user
      end)

      const_set(:Friendship, Class.new(Unison::PrimitiveTuple::Base) do
        member_of Unison::Relations::Set.new(:friendships)
        attribute_accessor :id, :integer
        attribute_accessor :from_id, :integer
        attribute_accessor :to_id, :integer

        belongs_to :from, :class_name => :User
        belongs_to :to, :class_name => :User
      end)

      const_set(:Profile, Class.new(Unison::PrimitiveTuple::Base) do
        member_of Unison::Relations::Set.new(:profiles)
        attribute_reader :id, :integer
        attribute_accessor :owner_id, :integer

        belongs_to :owner, :class_name => :User
        belongs_to :yoga_owner, :class_name => :User, :foreign_key => :owner_id do |owner|
          owner.where(User[:hobby].eq("Yoga"))
        end
      end)

      const_set(:Photo, Class.new(Unison::PrimitiveTuple::Base) do
        member_of Unison::Relations::Set.new(:photos)
        attribute :id, :integer
        attribute :user_id, :integer
        attribute :name, :string

        belongs_to :user
      end)

      const_set(:Account, Class.new(Unison::PrimitiveTuple::Base) do
        member_of Unison::Relations::Set.new(:accounts)

        class << self
          def active?
            self[:deactivated_at].eq(nil)
          end
        end

        attribute :id, :integer
        attribute :user_id, :integer
        attribute :name, :string
        attribute_accessor :deactivated_at, :datetime
        belongs_to :owner, :foreign_key => :user_id, :class_name => :User
      end)
    end

    users_set.insert(User.new(:id => 1, :name => "Nathan", :hobby => "Yoga"))
    users_set.insert(User.new(:id => 2, :name => "Corey", :hobby => "Drugs & Art & Burning Man"))
    users_set.insert(User.new(:id => 3, :name => "Ross", :hobby => "Manicorn"))

    life_goals_set.insert(LifeGoal.new(:id => 1, :user_id => 1))
    life_goals_set.insert(LifeGoal.new(:id => 2, :user_id => 2))
    life_goals_set.insert(LifeGoal.new(:id => 3, :user_id => 3))

    friendships_set.insert(Friendship.new(:id => 1, :to_id => 2, :from_id => 1))
    friendships_set.insert(Friendship.new(:id => 2, :to_id => 3, :from_id => 1))
    friendships_set.insert(Friendship.new(:id => 2, :to_id => 1, :from_id => 2))
    friendships_set.insert(Friendship.new(:id => 2, :to_id => 3, :from_id => 2))
    friendships_set.insert(Friendship.new(:id => 2, :to_id => 1, :from_id => 3))

    profiles_set.insert(Profile.new(:id => 1, :owner_id => 1))
    profiles_set.insert(Profile.new(:id => 2, :owner_id => 2))
    profiles_set.insert(Profile.new(:id => 3, :owner_id => 3))

    photos_set.insert(Photo.new(:id => 1, :user_id => 1, :name => "Photo 1"))
    photos_set.insert(Photo.new(:id => 2, :user_id => 1, :name => "Photo 2"))
    photos_set.insert(Photo.new(:id => 3, :user_id => 2, :name => "Photo 3"))

    accounts_set.insert(Account.new(:id => 1, :user_id => 1, :name => "Account 1", :deactivated_at => nil))
    accounts_set.insert(Account.new(:id => 2, :user_id => 1, :name => "Account 2", :deactivated_at => nil))
    accounts_set.insert(Account.new(:id => 3, :user_id => 2, :name => "Account 3", :deactivated_at => Time.utc(2008, 8, 2)))
  end

  config.after do
    Object.class_eval do
      remove_const :User
      remove_const :LifeGoal
      remove_const :Friendship
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

  def life_goals_set
    LifeGoal.relation
  end

  def friendships_set
    Friendship.relation
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
    insert_subscription_node + delete_subscription_node + tuple_update_subscription_node
  end
end