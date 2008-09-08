module Models
  class Game < Unison::Tuple::Base
    # automate this for the default case
    member_of Relations::Set.new(:games)

    attribute :id
    attribute :deactivated_at
    attribute :current_question_id

    # has_many :game_sessions
    relates_to_many :game_sessions do
      GameSession.where(GameSession[:game_id].eq(self[:id]))
    end

    relates_to_many :active_game_sessions do
      game_sessions.where(GameSession[:deactivated_at].eq(nil))
    end

    # belongs_to :current_question, :class_name => :Question
    relates_to_one :current_question do
      Question.where(Question[:id].eq(signal(:current_question_id)))
    end

#    relates_to_one :next_question do
#      Question.where(Question[:index].gt(current_question.signal(:index)))
#    end

    relates_to_many :current_answers do
      Answer.where(Answer[:question_id].eq(signal(:current_question_id)))
    end
  end
end