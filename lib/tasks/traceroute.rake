desc 'Prints out unused routes and unreachable action methods'
task :traceroute => :environment do
  traceroute = Traceroute.new Rails.application
  traceroute.load_everything!

  defined_action_methods = traceroute.defined_action_methods

  routed_actions = traceroute.routed_actions
  non_error_routed_actions = routed_actions.select {|ra| ra.error.nil? }
  errors = routed_actions.map(&:error).compact

  unused_routes = non_error_routed_actions.map(&:controller_action_string) - defined_action_methods
  unreachable_action_methods = defined_action_methods - non_error_routed_actions.map(&:controller_action_string)

  if errors
    puts "Errors"
    errors.each {|e| puts "  #{e}"}
  end
  puts "Unused routes (#{unused_routes.count}):"
  unused_routes.each {|route| puts "  #{route}"}
  puts "Unreachable action methods (#{unreachable_action_methods.count}):"
  unreachable_action_methods.each {|action| puts "  #{action}"}
end
