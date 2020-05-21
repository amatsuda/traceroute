# frozen_string_literal: true

desc 'Prints out unused routes and unreachable action methods'
task :traceroute => :environment do
  traceroute = Traceroute.new Rails.application
  traceroute.load_everything!

  check_unused_routes = !ENV['UNREACHABLE_ACTION_METHODS_ONLY'] && !ENV['OVERRIDDEN_ROUTES_ONLY']
  check_unreachable_action_methods = !ENV['UNUSED_ROUTES_ONLY'] && !ENV['OVERRIDDEN_ROUTES_ONLY']
  check_overridden_routes = !ENV['UNREACHABLE_ACTION_METHODS_ONLY'] && !ENV['UNUSED_ROUTES_ONLY']
  failed_checks = []

  if check_unused_routes
    unused_routes = traceroute.unused_routes
    failed_checks << :unused_routes if unused_routes.present?

    puts "Unused routes (#{unused_routes.count}):"
    unused_routes.each {|route| puts "  #{route}"}
    puts
  end

  if check_unreachable_action_methods
    unreachable_action_methods = traceroute.unreachable_action_methods
    failed_checks << :unreachable_action_methods if unreachable_action_methods.present?

    puts "Unreachable action methods (#{unreachable_action_methods.count}):"
    unreachable_action_methods.each {|action| puts "  #{action}"}
    puts
  end

  if check_overridden_routes
    overridden_routes = traceroute.overridden_routes
    failed_checks << :overridden_routes if overridden_routes.present?

    puts "Overridden routes (#{overridden_routes.count} #{"group".pluralize(overridden_routes.count)}):"
    overridden_routes.each do |overriding_route, overridden_group|
      puts "  #{overriding_route}"

      overridden_group.each { |overridden_route| puts "    #{overridden_route}" }
    end
    puts
  end

  if ENV['FAIL_ON_ERROR'] && failed_checks.present?
    error_message = "#{failed_checks.join(", ")} detected.".humanize
    fail error_message
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

  desc 'Prints out overridden routes'
  task :overridden_routes => :environment do
    ENV['OVERRIDDEN_ROUTES_ONLY'] = '1'
    Rake::Task[:traceroute].invoke
  end
end
