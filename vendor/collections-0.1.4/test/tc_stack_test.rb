require File.dirname(__FILE__) + '/test_helper.rb'

class TcStackTest < Test::Unit::TestCase

  def test_new_stack
    stack = Stack.new
    assert stack.empty?,  "A new stack should be empty"
    assert_equal 0, stack.size
    assert_equal 0, stack.length
    
    # peek and pop should fail
    
  end
  
  def test_push_pop
    stack = Stack.new
    
    stack << "A"
    assert !stack.empty?
    assert_equal 1, stack.size
    
    stack.push "B"
    assert_equal 2, stack.size
    
    assert_equal "B", stack.pop
    assert_equal 1, stack.size
    
    assert_equal "A", stack.pop
    assert_equal 0, stack.size
    assert stack.empty?      
  end
  
  def test_push_peek_pop
    stack = Stack.new
    
    stack << "A"
    stack << "B"
    assert !stack.empty?
    assert_equal 2, stack.size
    
    # Top item is "B"
    assert_equal "B", stack.peek
    assert_equal 2, stack.size
    
    assert_equal "B", stack.pop
    assert_equal 1, stack.size      
    
    # Now top item is "A"
    assert_equal "A", stack.peek
    assert_equal 1, stack.size      
    
    assert_equal "A", stack.pop
    assert_equal 0, stack.size         
  end
end