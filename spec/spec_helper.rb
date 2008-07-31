require "rubygems"
require "spec"
$LOAD_PATH.push("#{File.dirname(__FILE__)}/../lib")
require "unison"

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
    end

    users_set.insert(User.new(:id => 1, :name => "Nathan", :hobby => "Yoga"))
    users_set.insert(User.new(:id => 2, :name => "Corey", :hobby => "Drugs & Art & Burning Man"))
    users_set.insert(User.new(:id => 3, :name => "Ross", :hobby => "Manicorn"))
    photos_set.insert(Photo.new(:id => 1, :user_id => 1, :name => "Photo 1"))
    photos_set.insert(Photo.new(:id => 2, :user_id => 1, :name => "Photo 2"))
    photos_set.insert(Photo.new(:id => 3, :user_id => 2, :name => "Photo 3"))
  end

  config.after do
    Object.class_eval do
      remove_const :User
      remove_const :Photo
    end
  end
end

class Spec::ExampleGroup
  include Unison

  def users_set
    User.relation
  end

  def photos_set
    Photo.relation
  end
end

module AddSubscriptionsMethodToRelation
  def subscriptions
    insert_subscriptions + delete_subscriptions + tuple_update_subscriptions
  end
end