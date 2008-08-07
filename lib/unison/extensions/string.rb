class String
  def to_sql
    "'#{gsub(/\\/, '\&\&').gsub(/'/, "''")}'"
  end
end