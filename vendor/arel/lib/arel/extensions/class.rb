class Class
  def attributes(*attrs)
    @attributes = attrs
    attr_reader *attrs
  end
  
  def deriving(*methods)
    methods.each { |m| derive m }
  end
  
  def derive(method_name)
    methods = {
      :initialize => "
        def #{method_name}(#{@attributes.join(',')})
          #{@attributes.collect { |a| "@#{a} = #{a}" }.join("\n")}
        end
      ",
      :== => "
        def ==(other)
          #{name} === other &&
          #{@attributes.collect { |a| "@#{a} == other.#{a}" }.join(" &&\n")}
        end
      "
    }
    class_eval methods[method_name], __FILE__, __LINE__
  end
  
  def hash_on(delegatee)
    define_method :eql? do |other|
      self == other
    end
    
    define_method :hash do
      @hash ||= delegatee.hash
    end
  end
end