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
      const_set(:User, Class.new(Unison::PrimitiveTuple::Base) do
        member_of Unison::Relations::Set.new(:users)
        
        attribute_accessor :id, :integer
        attribute_accessor :name, :string
        attribute_accessor :hobby, :string
        attribute_accessor :best_friend_id, :integer

        relates_to_n :photos do
          Photo.where(Photo[:user_id].eq(self[:id]))
        end


        has_one :profile
        relates_to_n :accounts do
          select_n(Account)
        end
        relates_to_n :active_accounts do
          select_n(Account).where(Account.active?)
        end

#        relates_to_1 :best_friend do
#          select_1(User, :foreign_key => :best_friend_id)
#        end

        relates_to_n :target_friendships do
          select_n(Friendship, :foreign_key => :target_id)
        end

        relates_to_n :source_friendships do
          select_n(Friendship, :foreign_key => :source_id)
        end
      end)

      const_set(:Friendship, Class.new(Unison::PrimitiveTuple::Base) do
        member_of Unison::Relations::Set.new(:friendships)
        attribute_accessor :id, :integer
        attribute_accessor :source_id, :integer
        attribute_accessor :target_id, :integer

#        relates_to_1 :source do
#          select_1(User, :foreign_key => :source_id)
#        end

#        relates_to_1 :target do
#          select_1(User, :foreign_key => :target_id)
#        end
      end)

      const_set(:Profile, Class.new(Unison::PrimitiveTuple::Base) do
        member_of Unison::Relations::Set.new(:profiles)
        attribute_reader :id, :integer
        attribute_accessor :user_id, :integer

        belongs_to :user
      end)

      const_set(:LifeGoal, Class.new(Unison::PrimitiveTuple::Base) do
        member_of Unison::Relations::Set.new(:life_goals)
        attribute :id, :integer
        attribute :owner_id, :integer

#        relates_to_1 do
#          select_1_parent(User, :owner_id)
#        end
        belongs_to :user
      end)

      const_set(:Photo, Class.new(Unison::PrimitiveTuple::Base) do
        member_of Unison::Relations::Set.new(:photos)
        attribute :id, :integer
        attribute :user_id, :integer
        attribute :name, :string

        relates_to_1(:user) do
          User.where(User[:id].eq(self[:user_id]))
        end
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
        belongs_to :user
      end)
    end

    users_set.insert(User.new(:id => 1, :name => "Nathan", :hobby => "Yoga", :best_friend_id => 2))
    users_set.insert(User.new(:id => 2, :name => "Corey", :hobby => "Drugs & Art & Burning Man", :best_friend_id => 3))
    users_set.insert(User.new(:id => 3, :name => "Ross", :hobby => "Manicorn", :best_friend_id => 1))

    friendships_set.insert(Friendship.new(:id => 1, :target_id => 2, :source_id => 1))
    friendships_set.insert(Friendship.new(:id => 2, :target_id => 3, :source_id => 1))
    friendships_set.insert(Friendship.new(:id => 2, :target_id => 1, :source_id => 2))
    friendships_set.insert(Friendship.new(:id => 2, :target_id => 3, :source_id => 2))
    friendships_set.insert(Friendship.new(:id => 2, :target_id => 1, :source_id => 3))

    profiles_set.insert(Profile.new(:id => 1, :user_id => 1))
    profiles_set.insert(Profile.new(:id => 2, :user_id => 2))
    profiles_set.insert(Profile.new(:id => 3, :user_id => 3))

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
      remove_const :Friendship
      remove_const :LifeGoal
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