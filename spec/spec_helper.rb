require "rubygems"
$LOAD_PATH.push("#{File.dirname(__FILE__)}/../lib")
require "unison"

Spec::Runner.configure do |config|
  config.mock_with :rr
  
  config.before do
    silence_warnings do
      Object.class_eval do
        const_set(:User, Class.new(Unison::Tuple::Base) do
          member_of Unison::Relations::Set.new(:users)
          attribute :id
          attribute :name

          relates_to_n :photos do
            Photo.where(Photo[:user_id].eq(self[:id]))
          end
        end)

        const_set(:Photo, Class.new(Unison::Tuple::Base) do
          member_of Unison::Relations::Set.new(:photos)
          attribute :id
          attribute :user_id
          attribute :name
        end)
      end
    end
  
    users_set.insert(User.new(:id => 1, :name => "Nathan"))
    users_set.insert(User.new(:id => 2, :name => "Corey"))
    users_set.insert(User.new(:id => 3, :name => "Ross"))
    photos_set.insert(Photo.new(:id => 1, :user_id => 1, :name => "Photo 1"))
    photos_set.insert(Photo.new(:id => 2, :user_id => 1, :name => "Photo 2"))
    photos_set.insert(Photo.new(:id => 3, :user_id => 2, :name => "Photo 3"))
  end
end

class Spec::ExampleGroup
  attr_reader :users_set, :User, :photos_set, :Photo

  def users_set
    User.relation
  end

  def photos_set
    Photo.relation
  end
end

module Kernel
  def silence_warnings
    old_verbose, $VERBOSE = $VERBOSE, nil
    yield
  ensure
    $VERBOSE = old_verbose
  end
end