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
      it "returns the client representation of all objects exposed to the client" do
        topic.to_hash.should == {
          'GameSession' => {
            '1' => Topics::GameSession::GameSession.new(Models::GameSession.find(1)),
            '2' => Topics::GameSession::GameSession.new(Models::GameSession.find(2))
          }
        }
      end
    end
  end
end