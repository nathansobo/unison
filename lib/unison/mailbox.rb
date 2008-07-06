module Unison
  class Mailbox
    attr_reader :events

    def initialize
      @subscriptions = Hash.new {|h,k| h[k] = Hash.new {|h,k| h[k] = []} }
      @events = []
    end

    def subscribe(relation, event_type, &proc)
      subscriptions[relation][event_type].push(proc)
      relation.subscribe(self, event_type)
    end

    def freeze
    end

    def take
      return if events.empty?
      event = events.shift
      subscriptions[event.relation][event.type].each do |proc|
        proc.call(event.object)
      end
    end

    def publish(event)
      events.push(event)
    end

    protected
    attr_reader :subscriptions
  end
end