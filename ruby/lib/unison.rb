dir = File.dirname(__FILE__)
$LOAD_PATH.unshift(File.expand_path("#{dir}/../vendor/arel/lib"))
$LOAD_PATH.unshift(File.expand_path("#{dir}/../vendor/collections-0.1.4/lib"))
require "arel"
require "collections"
require "rubygems"
require "sequel"

# TODO: Make a better fix
class String
  remove_method :to_sql
end

require "#{dir}/unison/adapters"
require "#{dir}/unison/repository"
require "#{dir}/unison/retainable"
require "#{dir}/unison/relations"
require "#{dir}/unison/predicates"
require "#{dir}/unison/attribute"
require "#{dir}/unison/signal"
require "#{dir}/unison/tuple"
require "#{dir}/unison/primitive_tuple"
require "#{dir}/unison/compound_tuple"
require "#{dir}/unison/subscription"
require "#{dir}/unison/subscription_node"

module Unison
  class << self
    def origin
      raise "You must set Unison.origin to a Repository" unless @origin
      @origin
    end
    attr_writer :origin
  end
end
