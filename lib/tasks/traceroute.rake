# frozen_string_literal: true

desc 'Prints out unused routes and unreachable action methods'
task traceroute: :environment do
  traceroute = Traceroute.new Rails.application
  traceroute.load_everything!

  defined_action_methods = traceroute.defined_action_methods

  routed_actions = traceroute.routed_actions

  unused_routes = routed_actions - defined_action_methods
  unreachable_action_methods = defined_action_methods - routed_actions

  puts "Unused routes (#{unused_routes.count}):"
  unused_routes.each {|route| puts "  #{route}"}
  puts
  puts "Unreachable action methods (#{unreachable_action_methods.count}):"
  unreachable_action_methods.each {|action| puts "  #{action}"}

  unless (unused_routes.empty? && unreachable_action_methods.empty?) || ENV['FAIL_ON_ERROR'] != "1"
    fail "Unused routes or unreachable action methods detected."
  end
end

namespace :traceroute do
  desc "Prints out unused routes"
  task unused_routes: :environment do
    traceroute = Traceroute.new Rails.application
    traceroute.load_everything!

    defined_action_methods = traceroute.defined_action_methods

    routed_actions = traceroute.routed_actions

    unused_routes = routed_actions - defined_action_methods

    puts "Unused routes (#{unused_routes.count}):"
    unused_routes.each {|route| puts "  #{route}"}

    unless unused_routes.empty? || ENV['FAIL_ON_ERROR'] != "1"
      fail "Unused routes."
    end
  end

  desc "Prints out unreachable action methods"
  task unreachable_action_methods: :environment do
    traceroute = Traceroute.new Rails.application
    traceroute.load_everything!

    defined_action_methods = traceroute.defined_action_methods

    routed_actions = traceroute.routed_actions

    unreachable_action_methods = defined_action_methods - routed_actions

    puts "Unreachable action methods (#{unreachable_action_methods.count}):"
    unreachable_action_methods.each {|action| puts "  #{action}"}

    unless (unreachable_action_methods.empty?) || ENV['FAIL_ON_ERROR'] != "1"
      fail "Unreachable action methods detected."
    end
  end
end
