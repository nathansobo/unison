module Unison
  class Mailbox
    attr_reader :events

    def initialize
      @subscriptions = Hash.new {|h,k| h[k] = Hash.new {|h,k| h[k] = []} }
      @frozen = false
    end

    def subscribe(relation, event_type, &proc)
      subscriptions[relation][event_type].push(proc)
      relation.subscribe(self, event_type)
    end

    def freeze
      @frozen = true
      @events = []
    end

    def frozen?
      @frozen
    end

    def take
      return if events.empty?
      invoke_callbacks(events.shift)
    end

    def publish(event)
      if frozen?
        events.push(event)
      else
        invoke_callbacks(event)
      end
    end

    protected
    attr_reader :subscriptions

    def invoke_callbacks(event)
      subscriptions[event.relation][event.type].each do |proc|
        proc.call(event.object)
      end
    end
  end
end