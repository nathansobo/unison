$LOAD_PATH.push("#{File.dirname(__FILE__)}/../lib")
require "unison"

Spec::Runner.configure do |config|
  config.before do
    @users_set = Unison::Set.new(:users)
    users_set.attribute(:id)
    users_set.attribute(:name)
  end
end

class Spec::ExampleGroup
  attr_reader :users_set
end