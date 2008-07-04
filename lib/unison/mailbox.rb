module Unison
  class Mailbox
    attr_reader :events

    def initialize
      @subscriptions = Hash.new {|h,k| h[k] = Hash.new {|h,k| h[k] = []} }
      @events = []
    end

    def subscribe(relation, event_type, &proc)
      subscriptions[relation][event_type].push(proc)
    end

    def freeze
    end

    def take
    end

    def push(event)
      events.push(event)
    end

    protected
    attr_reader :subscriptions
  end
end