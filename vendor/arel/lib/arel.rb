$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rubygems'
require 'activesupport'
require 'activerecord' unless $arel_requires_active_record == false

require 'arel/arel'
require 'arel/extensions'
require 'arel/sql'
require 'arel/predicates'
require 'arel/relations'
require 'arel/engine'
require 'arel/session'
require 'arel/primitives'