dir = File.dirname(__FILE__)
$LOAD_PATH.unshift(File.expand_path("#{dir}/../vendor/arel/lib"))
$LOAD_PATH.unshift(File.expand_path("#{dir}/../vendor/collections-0.1.4/lib"))
require "arel"
require "collections"
require "rubygems"
require "sequel"
require "guid"
require "json"

# TODO: Arel implements to_sql on String, which causes problems. Make a better fix.
class String
  remove_method :to_sql
end

require "#{dir}/unison/extensions/object"
require "#{dir}/unison/extensions/array"
require "#{dir}/unison/subscription_node"
require "#{dir}/unison/subscription"
require "#{dir}/unison/adapters"
require "#{dir}/unison/repository"
require "#{dir}/unison/retainable"
require "#{dir}/unison/relations"
require "#{dir}/unison/predicates"
require "#{dir}/unison/attributes"
require "#{dir}/unison/signals"
require "#{dir}/unison/field"
require "#{dir}/unison/primitive_field"
require "#{dir}/unison/synthetic_field"
require "#{dir}/unison/tuples"
require "#{dir}/unison/relation_definition"

module Unison
  class << self
    def origin
      raise "You must set Unison.origin to a Repository" unless @origin
      @origin
    end
    attr_writer :origin
    
    def models_module
      @models_module ||= Object
    end
    attr_writer :models_module
    
    def and(*args)
      Predicates::And.new(*args)
    end

    def or(*args)
      Predicates::Or.new(*args)
    end
    
    def clear_all_sets
      Relations::Set.clear_all
    end

    def load_all_fixtures
      Relations::Set.load_all_fixtures
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
