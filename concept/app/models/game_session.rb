module Models
  class GameSession < Tuple::Base
    # automate this for the default case
    member_of Relations::Set.new(:game_sessions)

    attribute :id
    attribute :answer_id
    attribute :deactivated_at

    relates_to_1 :answer do
      Answer.where(Answer[:id].eq(signal(:answer_id)))
    end

    relates_to_1 :game do
      Game.where(Game[:id].eq(game_id))
    end
  end
end