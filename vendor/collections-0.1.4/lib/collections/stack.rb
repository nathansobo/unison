# = Stack
#
# == Description
# This class represents a last-in-first-out (LIFO) stack of objects.
# 
# A Ruby array provides most of the methods necessary to implement a stack.
# This class is just a small wrapper to narrow down array methods to get
# stack only behaviour to adhere to the LIFO constraints.
# 
# == Usage
#
#--
# (see examples directory under the ruby gems root directory)
#++
#  require 'rubygems'
#  require 'collections'
#  # or
#  require 'collections/stack'
#  stack = Stack.new
#  stack.push "A"
#  stack << "B"
#  stack.peek # => "B"
#  stack.size # => 2
#  stack.pop # => "B"
#  stack.peek # => "A"
#  stack.size # => 1
#
# == Source
# http://code.juretta.com/project/collections/
#
# == Author
#  Stefan Saasen <s@juretta.com>
#
# == Licence
#  MIT
class Stack
  def initialize
    @stack = []
  end

  # Returns the size of the stack.
  def size
    @stack.size
  end
  alias :length :size

  # Returns +true+ if this Stack is empty, false otherwise
  def empty?
    @stack.empty?
  end
  
  # Returns the n-th item of this stack without removing it. 
  # If used without an argument or if the argument equals 0 it
  # returns the top item without removing it.
  def peek(i = 0)
    @stack[size-i-1]
  end
  alias :top :peek

  # Removes the object at the top of this stack and returns that 
  # object as the value of this function. 
  def pop
    @stack.pop
  end
  
  # Pushes an item onto the top of this stack.
  def push(v)
    @stack.push v
  end
  alias :<< :push

end