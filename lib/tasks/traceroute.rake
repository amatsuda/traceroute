# frozen_string_literal: true

desc 'Prints out unused routes and unreachable action methods'
task :traceroute => :environment do |t, args|
  ignore_helpers_option = '--ignore-helpers'
  ignore_helpers = ARGV.include?(ignore_helpers_option) || args.include?(ignore_helpers_option)

  traceroute = Traceroute.new Rails.application
  traceroute.load_everything!

  defined_action_methods = traceroute.defined_action_methods

  if ignore_helpers
    helper_methods = (traceroute.user_helper_methods + traceroute.framework_helper_methods).map(&:to_s)
    action_methods_without_helpers = defined_action_methods.reject { |m| helper_methods.include?(m.gsub(/.+#/, ''))}
  else
    action_methods_without_helpers = defined_action_methods
  end

  routed_actions = traceroute.routed_actions

  unused_routes = routed_actions - defined_action_methods
  unreachable_action_methods = action_methods_without_helpers - routed_actions

  puts "Unused routes (#{unused_routes.count}):"
  unused_routes.each {|route| puts "  #{route}"}
  puts
  puts "Unreachable action methods (#{unreachable_action_methods.count}):"
  unreachable_action_methods.each {|action| puts "  #{action}"}

  unless (unused_routes.empty? && unreachable_action_methods.empty?) || ENV['FAIL_ON_ERROR'] != "1"
    fail "Unused routes or unreachable action methods detected."
  end
end
