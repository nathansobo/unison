dir = File.dirname(__FILE__)
require "java"
#Dir["#{dir}/vendor/terracotta-2.6.4/lib/**/*.jar"].each do |jar|
#  require jar
#end
require "#{dir}/vendor/terracotta-2.6.4/lib/tc.jar"

include_class "com.tc.object.event.DmiManager"

TC = com.tc.object.bytecode.ManagerUtil
#
module DSO
  READ_LOCK = com.tc.object.lockmanager.api.LockLevel::READ
  WRITE_LOCK = com.tc.object.lockmanager.api.LockLevel::WRITE
  CONCURRENT_LOCK = com.tc.object.lockmanager.api.LockLevel::CONCURRENT;

  def DSO.create_root(name, object)
    guard_with_named_lock(name, WRITE_LOCK) do
      TC.lookupOrCreateRoot name, object
    end
  end

  def DSO.guard(object, type = WRITE_LOCK)
    TC.monitorEnter object, type
    begin
      yield
    ensure
      TC.monitorExit object
    end
  end

  def DSO.guard_with_named_lock(name, type = WRITE_LOCK)
    TC.beginLock name, type
    begin
      yield
    ensure
      TC.commitLock name
    end
  end

  # Dispatches a Distributed Method Call (DMI). Ensures that the
  # particular method will be invoked on all nodes in the cluster.
  def DSO.dmi(object, methodName, arguments)
    TC.distributedMethodCall object, methodName, arguments
  end
end

class Chatter
  def initialize
    @name = "root"
    @messages = DSO.create_root "chatter", java.util.ArrayList.new
    puts "Ñ Hi #{@name}. Welcome to Chatter. Press Enter to refresh Ñ"
  end

  def run
    while true do
      print "Enter Text>>"
      text = STDIN.gets.chomp
      if text.length > 0 then
        DSO.guard @messages do
          @messages.add "[#{Time.now} Ñ #{@name}] #{text}"
          puts @messages
        end
      else
        puts @messages
     end
    end
  end
end

Chatter.new.run
