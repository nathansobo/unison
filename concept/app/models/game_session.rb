module Models
  class GameSession < Unison::Tuple::Base
    # automate this for the default case
    member_of Relations::Set.new(:game_sessions)

    attribute :id
    attribute :game_id
    attribute :answer_id
    attribute :deactivated_at

    relates_to_one :answer do
      Answer.where(Answer[:id].eq(signal(:answer_id)))
    end

    relates_to_one :game do
      Game.where(Game[:id].eq(self[:game_id]))
    end

    alias_method :room, :game
  end
end