desc 'Prints out unused routes and unreachable action methods'
task :traceroute => :environment do
  traceroute = Traceroute.new Rails.application
  traceroute.load_everything!

  defined_action_methods = traceroute.defined_action_methods

  routed_actions = traceroute.routed_actions

  unused_routes = routed_actions - defined_action_methods
  unreachable_action_methods = defined_action_methods - routed_actions

  puts "Unused routes (#{unused_routes.count}):"
  unused_routes.each {|route| puts "  #{route}"}
  puts "Unreachable action methods (#{unreachable_action_methods.count}):"
  unreachable_action_methods.each {|action| puts "  #{action}"}

  unless (unused_routes.empty? && unreachable_action_methods.empty?) || ENV['FAIL_ON_ERROR'].blank?
    fail "Unused routes or unreachable action methods detected."
  end
end
