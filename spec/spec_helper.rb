$LOAD_PATH.push("#{File.dirname(__FILE__)}/../lib")
require "unison"

Spec::Runner.configure do |config|
  config.before do
    @users_set = Unison::Relations::Set.new(:users)
    users_set.attribute(:id)
    users_set.attribute(:name)
    @user_class = users_set.tuple_class

    @photos_set = Unison::Relations::Set.new(:photos)
    photos_set.attribute(:id)
    photos_set.attribute(:user_id)
    photos_set.attribute(:name)
    @photo_class = photos_set.tuple_class
  end
end

class Spec::ExampleGroup
  attr_reader :users_set, :user_class, :photos_set, :photo_class
end