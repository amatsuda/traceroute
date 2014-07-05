desc 'Prints out unused routes and unreachable action methods'
task :traceroute => :environment do
  Traceroute.load_everything!

  routes = Traceroute.routes

  defined_action_methods = ActionController::Base.descendants.map do |controller|
    controller.action_methods.reject {|a| (a =~ /\A(_conditional)?_callback_/) || (a == '_layout_from_proc')}.map do |action|
      "#{controller.controller_path}##{action}"
    end
  end.flatten

  routed_actions = routes.map do |r|
    if r.requirements[:controller].blank? && r.requirements[:action].blank? && (r.path == '/:controller(/:action(/:id(.:format)))')
      %Q["#{r.path}"  This is a legacy wild controller route that's not recommended for RESTful applications.]
    else
      "#{r.requirements[:controller]}##{r.requirements[:action]}"
    end
  end

  unused_routes = routed_actions - defined_action_methods
  unreachable_action_methods = defined_action_methods - routed_actions

  puts "Unused routes (#{unused_routes.count}):"
  unused_routes.each {|route| puts "  #{route}"}
  puts "Unreachable action methods (#{unreachable_action_methods.count}):"
  unreachable_action_methods.each {|action| puts "  #{action}"}
end
