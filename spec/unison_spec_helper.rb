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
connection.create_table :teams do
  column :id, :string
  column :name, :string
end

connection.create_table :users do
  column :id, :string
  column :name, :string
  column :hobby, :string
  column :team_id, :string
  column :developer, :integer
  column :show_fans, :boolean
end

connection.create_table :life_goals do
  column :id, :string
  column :user_id, :string
end

connection.create_table :friendships do
  column :id, :string
  column :from_id, :string
  column :to_id, :string
end

connection.create_table :profiles do
  column :id, :string
  column :owner_id, :string
end

connection.create_table :photos do
  column :id, :string
  column :name, :string
  column :user_id, :string
  column :camera_id, :string
end

connection.create_table :cameras do
  column :id, :string
  column :name, :string
end

connection.create_table :accounts do
  column :id, :string
  column :name, :string
  column :user_id, :string
  column :deactivated_at, :string
  column :employee_id, :integer
end

Spec::Runner.configure do |config|
  config.mock_with :rr

  config.before do
    Unison.test_mode = true

    users = connection[:users]
    users.delete
    users << {:id => "buffington", :name => "Buffington", :hobby => "Bots", :team_id => "mangos", :show_fans => true}
    users << {:id => "keefa", :name => "Keefa", :hobby => "Begging", :team_id => "chargers", :show_fans => true}

    photos = connection[:photos]
    photos.delete
    photos << {:id => "buffing_photo", :user_id => "buffington", :name => "Photo of Buffington.", :camera_id => "nikkon_d50"}
    photos << {:id => "buffing_bad_photo", :user_id => "buffington", :name => "Another photo of Buffington. This one is bad.", :camera_id => "nikkon_d50"}
    photos << {:id => "keefa_kicking_teddys_ass", :user_id => "keefa", :name => "Photo of Keefa in a dog fight. She's totally kicking Teddy's ass.", :camera_id => "sony_cybershot"}

    cameras = connection[:cameras]
    cameras.delete
    cameras << {:id => "nikkon_d50", :name => "Nikon D50"}
    cameras << {:id => "sony_cybershot", :name => "Sony CyberShot"}


    Object.class_eval do
      const_set(:Team, Class.new(Unison::PrimitiveTuple) do
        member_of Unison::Relations::Set.new(:teams)

        attribute_accessor :id, :string
        attribute_accessor :name, :string

        has_many :users
        has_many :photos, :through => :users

        has_many :friendships_from_users, :through => :users, :foreign_key => :from_id, :class_name => "Friendship"
        has_many :friendships_to_users, :through => :users, :foreign_key => :to_id, :class_name => "Friendship"
      end)

      const_set(:User, Class.new(Unison::PrimitiveTuple) do
        member_of Unison::Relations::Set.new(:users)

        attribute_accessor :id, :string
        attribute_accessor :name, :string
        attribute_accessor :hobby, :string, :default => "Bomb construction"
        attribute_accessor :team_id, :string
        attribute_accessor :developer, :boolean
        attribute_accessor :show_fans, :boolean, :default => true
        synthetic_attribute :conqueror_name do
          signal(:name) do |name|
            "#{name} the Great!"
          end
        end

        def polymorphic_allocate(attrs)
          if attrs[:developer]
            Developer.allocate
          else
            super
          end
        end

        has_many :photos
        belongs_to :team

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

      const_set(:Developer, Class.new(User) do

      end)

      const_set(:LifeGoal, Class.new(Unison::PrimitiveTuple) do
        member_of Unison::Relations::Set.new(:life_goals)
        attribute_accessor :id, :string
        attribute_accessor :user_id, :string

        belongs_to :user
      end)

      const_set(:Friendship, Class.new(Unison::PrimitiveTuple) do
        member_of Unison::Relations::Set.new(:friendships)
        attribute_accessor :id, :string
        attribute_accessor :from_id, :string
        attribute_accessor :to_id, :string

        belongs_to :from, :class_name => :User
        belongs_to :to, :class_name => :User
      end)

      const_set(:Profile, Class.new(Unison::PrimitiveTuple) do
        member_of Unison::Relations::Set.new(:profiles)
        attribute_reader :id, :string
        attribute_accessor :owner_id, :string

        belongs_to :owner, :class_name => :User
        belongs_to :yoga_owner, :class_name => :User, :foreign_key => :owner_id do |owner|
          owner.where(User[:hobby].eq("Yoga"))
        end
        has_many :yoga_photos, :through => :yoga_owner, :class_name => :Photo
        has_many :friendships_to_me, :through => :owner, :foreign_key => :to_id, :class_name => :Friendship
        has_many :friendships_from_me, :through => :owner, :foreign_key => :from_id, :class_name => :Friendship
      end)

      const_set(:Photo, Class.new(Unison::PrimitiveTuple) do
        member_of Unison::Relations::Set.new(:photos)
        attribute_accessor :id, :string
        attribute_accessor :user_id, :string
        attribute_accessor :camera_id, :string
        attribute_accessor :name, :string

        belongs_to :user
        belongs_to :camera
      end)

      const_set(:Camera, Class.new(Unison::PrimitiveTuple) do
        member_of Unison::Relations::Set.new(:cameras)
        attribute_accessor :id, :string
        attribute_accessor :name, :string

        has_many :photos
      end)

      const_set(:Account, Class.new(Unison::PrimitiveTuple) do
        member_of Unison::Relations::Set.new(:accounts)

        class << self
          def active?
            self[:deactivated_at].eq(nil)
          end
        end

        attribute_accessor :id, :string
        attribute_accessor :user_id, :string
        attribute_accessor :name, :string
        attribute_accessor :deactivated_at, :datetime
        attribute_accessor :employee_id, :integer
        belongs_to :owner, :foreign_key => :user_id, :class_name => :User

        def active?
          !deactivated_at
        end
      end)
    end

    teams_set.insert(Team.new(:id => "mangos", :name => "The Mangos"))
    teams_set.insert(Team.new(:id => "chargers", :name => "San Diego Superchargers"))

    users_set.insert(User.new(:id => "nathan", :name => "Nathan", :hobby => "Yoga", :team_id => "chargers"))
    users_set.insert(User.new(:id => "corey", :name => "Corey", :hobby => "Drugs & Art & Burning Man", :team_id => "mangos"))
    users_set.insert(User.new(:id => "ross", :name => "Ross", :hobby => "Manicorn", :team_id => "mangos"))

    life_goals_set.insert(LifeGoal.new(:id => "nathan_goal", :user_id => "nathan"))
    life_goals_set.insert(LifeGoal.new(:id => "corey_goal", :user_id => "corey"))
    life_goals_set.insert(LifeGoal.new(:id => "ross_goal", :user_id => "ross"))

    friendships_set.insert(Friendship.new(:id => "nathan_to_corey", :to_id => "corey", :from_id => "nathan"))
    friendships_set.insert(Friendship.new(:id => "nathan_to_ross", :to_id => "ross", :from_id => "nathan"))
    friendships_set.insert(Friendship.new(:id => "corey_to_nathan", :to_id => "nathan", :from_id => "corey"))
    friendships_set.insert(Friendship.new(:id => "corey_to_ross", :to_id => "ross", :from_id => "corey"))
    friendships_set.insert(Friendship.new(:id => "ross_to_nathan", :to_id => "nathan", :from_id => "ross"))

    profiles_set.insert(Profile.new(:id => "nathan_profile", :owner_id => "nathan"))
    profiles_set.insert(Profile.new(:id => "corey_profile", :owner_id => "corey"))
    profiles_set.insert(Profile.new(:id => "ross_profile", :owner_id => "ross"))

    photos_set.insert(Photo.new(:id => "nathan_photo_1", :user_id => "nathan", :name => "Nathan Photo 1", :camera_id => "minolta"))
    photos_set.insert(Photo.new(:id => "nathan_photo_2", :user_id => "nathan", :name => "Nathan Photo 2", :camera_id => "minolta"))
    photos_set.insert(Photo.new(:id => "corey_photo_1", :user_id => "corey", :name => "Corey Photo 1", :camera_id => "minolta"))

    accounts_set.insert(Account.new(:id => "nathan_pivotal_account", :user_id => "nathan", :name => "Nathan's Pivotal Account", :deactivated_at => Time.utc(2008, 8, 31), :employee_id => 1))
    accounts_set.insert(Account.new(:id => "nathan_account_2", :user_id => "nathan", :name => "Nathan's Account 2", :deactivated_at => nil, :employee_id => 2))
    accounts_set.insert(Account.new(:id => "corey_account", :user_id => "corey", :name => "Corey's Account", :deactivated_at => nil, :employee_id => 3))
    accounts_set.insert(Account.new(:id => "ross_account", :user_id => "ross", :name => "Ross's Account", :deactivated_at => Time.utc(2008, 8, 2), :employee_id => 4))

    cameras_set.insert(Camera.new(:id => "minolta", :name => "Minolta"))
    cameras_set.insert(Camera.new(:id => "canon", :name => "Canon"))
  end

  config.after do
    Object.class_eval do
      remove_const :Team
      remove_const :User
      remove_const :Developer
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

  def publicize(object, *methods)
    eigenclass = class << object; self; end
    eigenclass.class_eval do
      public *methods
    end
  end

  def teams_set
    Team.set
  end

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
