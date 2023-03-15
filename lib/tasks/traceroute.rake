# frozen_string_literal: true

desc 'Prints out unused routes and unreachable action methods'
task :traceroute => :environment do
  traceroute = Traceroute.new Rails.application
  traceroute.load_everything!

  unless ENV['UNREACHABLE_ACTION_METHODS_ONLY']
    unused_routes = traceroute.unused_routes
    puts "Unused routes (#{unused_routes.count}):"
    unused_routes.each {|route| puts "  #{route}"}
  end

  puts unless (ENV['UNREACHABLE_ACTION_METHODS_ONLY'] || ENV['UNUSED_ROUTES_ONLY'])

  unless ENV['UNUSED_ROUTES_ONLY']
    unreachable_action_methods = traceroute.unreachable_action_methods
    puts "Unreachable action methods (#{unreachable_action_methods.count}):"
    unreachable_action_methods.each {|action| puts "  #{action}"}
  end

  unused_action_checks = traceroute.unused_ignored_unreachable_action_methods
  unless unused_action_checks.empty?
    puts "Unused action method ignores present (#{unused_action_checks.count}):"
    unused_action_checks.each {|action| puts "  #{action}"}
  end

  unused_route_checks = traceroute.unused_ignored_unused_routes
  unless unused_route_checks.empty?
    puts "Unused route ignores present (#{unused_route_checks.count}):"
    unused_route_checks.each {|route| puts "  #{route}"}
  end

  if ENV['FAIL_ON_ERROR'] && ((!ENV['UNREACHABLE_ACTION_METHODS_ONLY'] && unused_routes.any?) || (!ENV['UNUSED_ROUTES_ONLY'] && unreachable_action_methods.any?))
    fail "Unused routes or unreachable action methods detected."
  end

  if ENV['FAIL_ON_ERROR'] && (unused_action_checks.any? || unused_route_checks.any?)
    fail "Unused routes or unreachable action ignore lines detected in config."
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
