require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

module Topics
  describe GameSession do
    attr_reader :game_session, :game, :topic
    before do
      @game_session = Models::GameSession.find(1)
      @game = game_session.game
      @topic = GameSession.new(game_session)
    end

    describe "#to_hash" do
      it "returns the ClientRepresentation of all objects exposed to the client" do
        topic.to_hash.should == {
          'Game' => {
            '1' => Topics::GameSession::Game.new(Models::Game.find(1))
          },
          'GameSession' => {
            '1' => Topics::GameSession::GameSession.new(Models::GameSession.find(1)),
            '2' => Topics::GameSession::GameSession.new(Models::GameSession.find(2))
          },
          'Question' => {
            '1' => Topics::GameSession::Question.new(Models::Question.find(1))
          }
        }
      end

      context "when the current Question changes" do
        it "updates the Topic hash to the new value of Question" do
          topic.to_hash
          game[:current_question_id] = 2
          topic.to_hash['Question'].should == {
            '2' => Topics::GameSession::Question.new(Models::Question.find(2))
          }
        end
      end
    end
  end
end