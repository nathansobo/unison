class Game < Tuple::Base
  # automate this for the default case
  member_of Relations::Set.new(:games)

  attribute :deactivated_at

  # has_many :game_sessions
  relates_to_n :active_game_sessions do
    GameSession.where(GameSession[:game_id].eq(self[:id]).where(GameSession[:deactivated_at].eq(null))
  end

  relates_to_n :answers do
    Answer.where(Answer[:question_id].eq(signal(:current_question_id)))
  end

  relates_to_1 :current_question do
    Question.where(Question[:id].eq(self[:current_question_id]))
  end


  # some more declarative way of initializing subscriptions?
  def initialize
    active_game_sessions.on_delete do |game_session|
      deactivate if active_game_sessions.empty?
    end
  end

  def deactivate
    self.deactivated_at = Time.now.utc
  end
end