class GameSession < Tuple::Base
  # automate this for the default case
  member_of Relations::Set.new(:game_sessions)

  attribute :deactivated_at

  relates_to_1 :game do
    Game.where(Game[:id].eq(game_id))
  end


end