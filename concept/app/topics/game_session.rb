module Topics
  class GameSession < Base
    topic_url "/game_sessions/:guid"
    expose_to_client :self, :game_sessions, :question, :answers

    def initialize(game_session)
      super
      self.root_object = game_session.game
    end

    # Specific representations for object types can be scoped under the topic's module
    # Otherwise a default representation can be used that forwards all declared attributes
    class Game < ClientRepresentation::Base

    end
  end
end