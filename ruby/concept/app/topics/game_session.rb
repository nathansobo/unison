module Topics
  class GameSession < Topics::Topic
#    topic_url "/game_sessions/:guid"
    expose_to_client :self
    expose_to_client :game_sessions
    expose_to_client :current_question
    expose_to_client :current_answers
#    expose_to_client :self, :game_sessions, :question, :answers

    attr_reader :session
    def initialize(session)
      super
      @session = session
    end

    def room
      session.room
    end

    # Specific representations for object types can be scoped under the topic's module
    # Otherwise a default representation can be used that forwards all declared attributes
    class Game < ClientRepresentation
      
    end

    class GameSession < ClientRepresentation

    end

    class Question < ClientRepresentation

    end

    class Answer < ClientRepresentation

    end
  end
end