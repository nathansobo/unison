class NilClass
  def equality_predicate_sql
    'IS'
  end

  def inequality_predicate_sql
    'IS NOT'
  end
end