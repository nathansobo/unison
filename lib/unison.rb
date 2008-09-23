dir = File.dirname(__FILE__)
$LOAD_PATH.unshift(File.expand_path("#{dir}/../vendor/arel/lib"))
$LOAD_PATH.unshift(File.expand_path("#{dir}/../vendor/collections-0.1.4/lib"))
require "arel"
require "collections"
require "rubygems"
require "sequel"
require "guid"

# TODO: Make a better fix
class String
  remove_method :to_sql
end

require "#{dir}/unison/extensions/object"
require "#{dir}/unison/adapters"
require "#{dir}/unison/repository"
require "#{dir}/unison/retainable"
require "#{dir}/unison/relations"
require "#{dir}/unison/predicates"
require "#{dir}/unison/attribute"
require "#{dir}/unison/signals"
require "#{dir}/unison/tuples"
require "#{dir}/unison/relation_definition"
require "#{dir}/unison/subscription"
require "#{dir}/unison/subscription_node"
require "#{dir}/unison/partial_inner_join"

module Unison
  class << self
    def origin
      raise "You must set Unison.origin to a Repository" unless @origin
      @origin
    end
    attr_writer :origin

    def and(*args)
      Predicates::And.new(*args)
    end

    def or(*args)
      Predicates::Or.new(*args)
    end

    attr_writer :test_mode
    def test_mode?
      @test_mode ||= false
    end
  end
  Tuples.constants.each do |constant_name|
    const_set(constant_name, Tuples.const_get(constant_name))
  end
end
