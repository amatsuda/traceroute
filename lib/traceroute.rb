module OnlyChecker
  def resources(*resources, &block)
    tmp_options = resources.dup.extract_options!
    resource_name = resources[0].to_s
    flattened_only_options = tmp_options[:only].nil? ? nil : [tmp_options[:only]].flatten.sort
    if flattened_only_options
      if flattened_only_options == [:create, :destroy, :edit, :index, :new, :show, :update]
        (Traceroute.dsl_warnings << "The :only option on the :#{resource_name} resource is unnecessary; it contains the default action set of [:new, :create, :index, :show, :edit, :update, :destroy]").uniq!
      elsif flattened_only_options == []
        (Traceroute.dsl_warnings << "Consider replacing the ':only => []' option on the :#{resource_name} resource with ':only => :none'").uniq!
      end
    end
    super
  end
end

class ActionDispatch::Routing::Mapper
  include OnlyChecker
end

class Traceroute
  VERSION = Gem.loaded_specs['traceroute'].version.to_s
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load File.join(File.dirname(__FILE__), 'tasks/traceroute.rake')
    end
  end

  def self.dsl_warnings
    @dsl_warnings ||= []
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
        %Q["#{r.path}"  This is a legacy wild controller route that's not recommended for RESTful applications.]
      else
        "#{r.requirements[:controller]}##{r.requirements[:action]}"
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
