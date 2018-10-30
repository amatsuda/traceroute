# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'
require 'rails'
require 'traceroute'
require_relative 'app'

Minitest::Test.class_eval do
  def assert_defined_action_methods(*actions)
    assert_equal actions.sort, @traceroute.defined_action_methods.reject {|a| a =~ /^rails/}.sort
  end

  def assert_routed_actions(*actions)
    assert_equal actions.sort, @traceroute.routed_actions.sort
  end
end
