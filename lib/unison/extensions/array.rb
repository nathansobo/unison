class Array
  def has_same_elements_as?(other)
    self.size == other.size && all? {|element| other.include?(element) }
  end
end