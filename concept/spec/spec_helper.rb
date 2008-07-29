require "rubygems"
require "spec"
dir = File.dirname(__FILE__)
$LOAD_PATH.push(File.expand_path("#{dir}/../../lib"))
require "unison"

require File.expand_path("#{dir}/../concept")

Spec::Runner.configure do |config|
  config.mock_with :rr
end

class Spec::ExampleGroup
  include Unison
  attr_reader :users_set, :User, :photos_set, :Photo

  def users_set
    User.relation
  end

  def photos_set
    Photo.relation
  end
end