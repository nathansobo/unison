class Time
  def to_sql
    strftime("%Y-%m-%d %H:%M:%S")
  end
end