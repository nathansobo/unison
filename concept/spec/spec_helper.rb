require "rubygems"
require "spec"
dir = File.dirname(__FILE__)
$LOAD_PATH.push(File.expand_path("#{dir}/../../lib"))
require "unison"

require File.expand_path("#{dir}/../concept")

Spec::Runner.configure do |config|
  config.mock_with :rr

  config.before do
    Models::Game.create(:id => 1, :current_question_id => 1)
    Models::GameSession.create(:id => 1, :game_id => 1)
    Models::GameSession.create(:id => 2, :game_id => 1)    
    Models::Question.create(:id => 1)
    Models::Question.create(:id => 2)    
    Models::Answer.create(:id => 1, :question_id => 1)
    Models::Answer.create(:id => 2, :question_id => 1)
    Models::Answer.create(:id => 3, :question_id => 2)
    Models::Answer.create(:id => 4, :question_id => 2)    
  end
end

class Spec::ExampleGroup
end