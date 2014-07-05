desc 'Prints out unused routes and unreachable action methods'
task :traceroute => :environment do
  Traceroute.load_everything!

  defined_action_methods = Traceroute.defined_action_methods

  routed_actions = Traceroute.routed_actions

  unused_routes = routed_actions - defined_action_methods
  unreachable_action_methods = defined_action_methods - routed_actions

  puts "Unused routes (#{unused_routes.count}):"
  unused_routes.each {|route| puts "  #{route}"}
  puts "Unreachable action methods (#{unreachable_action_methods.count}):"
  unreachable_action_methods.each {|action| puts "  #{action}"}
end
