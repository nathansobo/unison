class Answer < Tuple::Base
  # automate this for the default case
  member_of Relations::Set.new(:answers)

  attribute :id
  attribute :question_id
  attribute :body

  relates_to_1 :question do
    Question.where(Question[:id].eq[question_id])
  end
end