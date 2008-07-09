class Game < Tuple::Base
  # automate this for the default case
  member_of Relations::Set.new(:games)

  attribute :id
  attribute :deactivated_at

  # has_many :game_sessions
  relates_to_n :active_game_sessions do
    GameSession.where(GameSession[:game_id].eq(id).where(GameSession[:deactivated_at].eq(null)))
  end

  # belongs_to :current_question, :class_name => :Question
  relates_to_1 :current_question do
    Question.where(Question[:id].eq(signal(:current_question_id)))
  end

  relates_to_1 :next_question do
    Question.where(Question[:index].gt(current_question.signal(:index)))
  end

  relates_to_n :answers do
    Answer.where(Answer[:question_id].eq(signal(:current_question_id)))
  end

  # some more declarative way of initializing subscriptions?
  def initialize
    self.current_question_id = Question.first.id
    active_game_sessions.on_update do |game_session|
      load_next_question if everyone_has_answered?
    end
    active_game_sessions.on_delete do |game_session|
      load_next_question if everyone_has_answered?
      deactivate if active_game_sessions.empty?
    end
  end

  def deactivate
    self.deactivated_at = Time.now.utc
  end

  def everyone_has_answered?
    active_game_sessions.all? do |game_session|
      answers.include?(game_session.answer)
    end
  end

  def load_next_question
    active_game_sessions.each do |game_session|
      game_session.answer_id = nil
    end
    self.current_question_id = next_question.id
  end
end