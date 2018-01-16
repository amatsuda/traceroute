desc 'Prints out unused routes and unreachable action methods'
task :traceroute => :environment do
  traceroute = Traceroute.new Rails.application
  traceroute.load_everything!

  defined_action_methods = traceroute.defined_action_methods

  routed_actions = traceroute.routed_actions

  unused_routes = routed_actions.reject do |action| 
    defined_action_methods.include?(action) || begin
      formats = ActionView::Base.default_formats
      handlers = ActionView::Template::Handlers.extensions
      options = { variants: [], locale: [], formats: formats , handlers: handlers }
      ActionController::Base.view_paths.exists? action.gsub("#", "/"), "", false, options
    end
  end
  unreachable_action_methods = defined_action_methods - routed_actions

  puts "Unused routes (#{unused_routes.count}):"
  unused_routes.each {|route| puts "  #{route}"}
  puts "Unreachable action methods (#{unreachable_action_methods.count}):"
  unreachable_action_methods.each {|action| puts "  #{action}"}

  unless (unused_routes.empty? && unreachable_action_methods.empty?) || ENV['FAIL_ON_ERROR'] != "1"
    fail "Unused routes or unreachable action methods detected."
  end
end
