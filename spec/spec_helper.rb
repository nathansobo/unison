require "rubygems"
require "spec"
dir = File.dirname(__FILE__)
$LOAD_PATH.push("#{dir}/../lib")
require "unison"

# TODO: BT/NS - Remove dependency on ActiveSupport
require "test/unit"
require "active_support"
require "#{dir}/spec_helpers/be_like"

connection = Sequel.sqlite
Unison.origin = Unison::Repository.new(connection)
connection.create_table :users do
  column :id, :integer
  column :name, :string
  column :hobby, :string
end

connection.create_table :life_goals do
  column :id, :integer
  column :user_id, :integer
end

connection.create_table :friendships do
  column :id, :integer
  column :from_id, :integer
  column :to_id, :integer
end

connection.create_table :profiles do
  column :id, :integer
  column :owner_id, :integer
end

connection.create_table :photos do
  column :id, :integer
  column :name, :string
  column :user_id, :integer
  column :camera_id, :integer
end

connection.create_table :cameras do
  column :id, :integer
  column :name, :string
end

connection.create_table :accounts do
  column :id, :integer
  column :name, :string
  column :user_id, :integer
  column :deactivated_at, :string
end

Spec::Runner.configure do |config|
  config.mock_with :rr
  
  config.before do
    Unison.test_mode = true

    users = connection[:users]
    users.delete
    users << {:id => 11, :name => "Buffington", :hobby => "Bots"}
    users << {:id => 12, :name => "Keefa", :hobby => "Begging"}

    photos = connection[:photos]
    photos.delete
    photos << {:id => 11, :user_id => 11, :name => "Photo of Buffington.", :camera_id => 10}
    photos << {:id => 12, :user_id => 11, :name => "Another photo of Buffington. This one is bad.", :camera_id => 10}
    photos << {:id => 13, :user_id => 12, :name => "Photo of Keefa in a dog fight. She's totally kicking Teddy's ass.", :camera_id => 11}

    cameras = connection[:cameras]
    cameras.delete
    cameras << {:id => 11, :name => "Nikon D50"}
    cameras << {:id => 12, :name => "Sony CyberShot"}


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

        has_many :friendships_to_me, :foreign_key => :to_id, :class_name => :Friendship
        has_many :fans, :through => :friendships_to_me, :class_name => :User, :foreign_key => :from_id

        has_many :friendships_from_me, :foreign_key => :from_id, :class_name => :Friendship
        has_many :heroes, :through => :friendships_from_me, :class_name => :User, :foreign_key => :to_id

        has_many :cameras, :through => :photos
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
        attribute_accessor :id, :integer
        attribute_accessor :user_id, :integer
        attribute_accessor :camera_id, :integer
        attribute_accessor :name, :string

        belongs_to :user
        belongs_to :camera
      end)

      const_set(:Camera, Class.new(Unison::PrimitiveTuple::Base) do
        member_of Unison::Relations::Set.new(:cameras)
        attribute_accessor :id, :integer
        attribute_accessor :name, :string

        has_many :photos
      end)

      const_set(:Account, Class.new(Unison::PrimitiveTuple::Base) do
        member_of Unison::Relations::Set.new(:accounts)

        class << self
          def active?
            self[:deactivated_at].eq(nil)
          end
        end

        attribute_accessor :id, :integer
        attribute_accessor :user_id, :integer
        attribute_accessor :name, :string
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
    friendships_set.insert(Friendship.new(:id => 3, :to_id => 1, :from_id => 2))
    friendships_set.insert(Friendship.new(:id => 4, :to_id => 3, :from_id => 2))
    friendships_set.insert(Friendship.new(:id => 5, :to_id => 1, :from_id => 3))

    profiles_set.insert(Profile.new(:id => 1, :owner_id => 1))
    profiles_set.insert(Profile.new(:id => 2, :owner_id => 2))
    profiles_set.insert(Profile.new(:id => 3, :owner_id => 3))

    photos_set.insert(Photo.new(:id => 1, :user_id => 1, :name => "Photo 1", :camera_id => 1))
    photos_set.insert(Photo.new(:id => 2, :user_id => 1, :name => "Photo 2", :camera_id => 1))
    photos_set.insert(Photo.new(:id => 3, :user_id => 2, :name => "Photo 3", :camera_id => 1))

    accounts_set.insert(Account.new(:id => 1, :user_id => 1, :name => "Account 1", :deactivated_at => nil))
    accounts_set.insert(Account.new(:id => 2, :user_id => 1, :name => "Account 2", :deactivated_at => nil))
    accounts_set.insert(Account.new(:id => 3, :user_id => 2, :name => "Account 3", :deactivated_at => Time.utc(2008, 8, 2)))

    cameras_set.insert(Camera.new(:id => 1, :name => "Minolta XD-11"))
  end

  config.after do
    Object.class_eval do
      remove_const :User
      remove_const :LifeGoal
      remove_const :Friendship
      remove_const :Profile
      remove_const :Photo
      remove_const :Camera
      remove_const :Account
    end
  end
end

class Spec::ExampleGroup
  include Unison

  def users_set
    User.set
  end

  def life_goals_set
    LifeGoal.set
  end

  def friendships_set
    Friendship.set
  end

  def profiles_set
    Profile.set
  end

  def photos_set
    Photo.set
  end

  def cameras_set
    Camera.set
  end

  def accounts_set
    Account.set
  end

  def origin
    Unison.origin
  end

  def connection
    origin.connection
  end
end

class Unison::Relations::Relation
  def all_subscriptions
    insert_subscription_node + delete_subscription_node + tuple_update_subscription_node
  end
end