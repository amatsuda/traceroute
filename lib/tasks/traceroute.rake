desc 'Prints out unused routes and unreachable action methods'
task :traceroute => :environment do
  Rails.application.eager_load!
  Rails.application.reload_routes!
  routes = if defined? Journey::Route
    Rails.application.routes.routes.reject {|r| r.path.spec.to_s =~ %r{/rails/info/properties|^#{Rails.application.config.assets.prefix}} }.reject {|r| r.name.nil? && r.requirements.blank?}
  else
    Rails.application.routes.routes.reject {|r| r.path =~ %r{/rails/info/properties|^#{Rails.application.config.assets.prefix}}}.reject {|r| r.name.nil? && r.requirements.blank?}
  end

  defined_action_methods = ApplicationController.descendants.map {|controller|
    controller.action_methods.reject {|a| (a =~ /\A(_conditional)?_callback_/) || (a == '_layout_from_proc')}.map do |action|
      "#{controller.controller_path}##{action}"
    end
  }.flatten

  routed_actions = routes.map do |r|
    if r.requirements[:controller].blank? && r.requirements[:action].blank? && (r.path == '/:controller(/:action(/:id(.:format)))')
      %Q["#{r.path}"  This is a legacy wild controller route that's not recommended for RESTful applications.]
    else
      "#{r.requirements[:controller]}##{r.requirements[:action]}"
    end
  end

  puts 'Unused routes:'
  (routed_actions - defined_action_methods).each {|a| puts "  #{a}"}
  puts 'Unreachable action methods:'
  (defined_action_methods - routed_actions).each {|a| puts "  #{a}"}
end
