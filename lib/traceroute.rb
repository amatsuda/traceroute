class Traceroute
  VERSION = Gem.loaded_specs['traceroute'].version.to_s
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load File.join(File.dirname(__FILE__), 'tasks/traceroute.rake')
    end
  end

  RoutedAction = Struct.new(:verb, :controller, :action, :error) do
    def controller_action_string
      "#{controller}##{action}"
    end
  end

  def initialize(app)
    @app = app
  end

  def load_everything!
    @app.eager_load!
    ::Rails::InfoController rescue NameError
    ::Rails::WelcomeController rescue NameError
    ::Rails::MailersController rescue NameError
    @app.reload_routes!

    Rails::Engine.subclasses.each(&:eager_load!)
  end

  def defined_action_methods
    ActionController::Base.descendants.map do |controller|
      controller.action_methods.reject {|a| (a =~ /\A(_conditional)?_callback_/) || (a == '_layout_from_proc')}.map do |action|
        "#{controller.controller_path}##{action}"
      end
    end.flatten
  end

  def routed_actions
    routes.map do |r|
      if r.requirements[:controller].blank? && r.requirements[:action].blank? && (r.path == '/:controller(/:action(/:id(.:format)))')
        RoutedAction.new nil, nil, nil, %Q["#{r.path}"  This is a legacy wild controller route that's not recommended for RESTful applications.]
      else
        verb_string = r.verb.source.match(/[A-Z]+/)[0] + " " rescue ""
        RoutedAction.new verb_string, r.requirements[:controller], r.requirements[:action]
      end
    end
  end

  private
  def routes
    routes = @app.routes.routes.reject {|r| r.name.nil? && r.requirements.blank?}

    routes.reject! {|r| r.app.is_a?(ActionDispatch::Routing::Mapper::Constraints) && r.app.app.respond_to?(:call)}

    if @app.config.respond_to?(:assets)
      exclusion_regexp = %r{^#{@app.config.assets.prefix}}

      routes.reject! do |route|
        path = (defined?(ActionDispatch::Journey::Route) || defined?(Journey::Route)) ? route.path.spec.to_s : route.path
        path =~ exclusion_regexp
      end
    end
    routes
  end
end
