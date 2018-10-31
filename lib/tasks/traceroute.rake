# frozen_string_literal: true

desc 'Prints out unused routes and unreachable action methods'
task :traceroute => :environment do
  traceroute = Traceroute.new Rails.application
  traceroute.load_everything!

  defined_action_methods = traceroute.defined_action_methods

  routed_actions = traceroute.routed_actions

  unless ENV['UNREACHABLE_ACTION_METHODS_ONLY']
    unused_routes = routed_actions - defined_action_methods
    puts "Unused routes (#{unused_routes.count}):"
    unused_routes.each {|route| puts "  #{route}"}
  end

  puts unless (ENV['UNREACHABLE_ACTION_METHODS_ONLY'] || ENV['UNUSED_ROUTES_ONLY'])

  unless ENV['UNUSED_ROUTES_ONLY']
    unreachable_action_methods = defined_action_methods - routed_actions
    puts "Unreachable action methods (#{unreachable_action_methods.count}):"
    unreachable_action_methods.each {|action| puts "  #{action}"}
  end

  if ENV['FAIL_ON_ERROR'] && ((!ENV['UNREACHABLE_ACTION_METHODS_ONLY'] && unused_routes.any?) || (!ENV['UNUSED_ROUTES_ONLY'] && unreachable_action_methods.any?))
    fail "Unused routes or unreachable action methods detected."
  end
end

namespace :traceroute do
  desc 'Prints out unused routes'
  task :unused_routes => :environment do
    ENV['UNUSED_ROUTES_ONLY'] = '1'
    Rake::Task[:traceroute].invoke
  end

  desc 'Prints out unreachable action methods'
  task :unreachable_action_methods => :environment do
    ENV['UNREACHABLE_ACTION_METHODS_ONLY'] = '1'
    Rake::Task[:traceroute].invoke
  end
end
