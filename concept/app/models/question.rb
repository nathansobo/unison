module Models
  class Question < Unison::Tuple::Base
    # automate this for the default case
    member_of Relations::Set.new(:questions)

    attribute :id
    attribute :body

    relates_to_many :answers do
      Answer.where(Answer[:question_id].eq(self[:id]))
    end
  end
end