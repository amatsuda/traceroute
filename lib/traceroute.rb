class Traceroute
  VERSION = Gem.loaded_specs['traceroute'].version.to_s
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load File.join(File.dirname(__FILE__), 'tasks/traceroute.rake')
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
    end.flatten.reject {|r| r.start_with? 'rails/'}
  end

  def routed_actions
    routes.map do |r|
      if r.requirements[:controller].blank? && r.requirements[:action].blank? && (r.path == '/:controller(/:action(/:id(.:format)))')
        %Q["#{r.path}"  This is a legacy wild controller route that's not recommended for RESTful applications.]
      else
        "#{r.requirements[:controller]}##{r.requirements[:action]}"
      end
    end.reject {|r| r.start_with? 'rails/'}
  end

  def user_helper_methods
    get_helper_modules.map(&:public_instance_methods).flatten
  end

  def framework_helper_methods
    ActionView::Helpers.constants
      .select { |c| c.to_s.include?('Helper') }
      .map { |c| ActionView::Helpers.const_get(c) }
      .map { |m| m.public_instance_methods }
      .flatten
      .uniq
  end

  private
  def routes
    routes = @app.routes.routes.reject {|r| r.name.nil? && r.requirements.blank?}

    routes.reject! {|r| r.app.is_a?(ActionDispatch::Routing::Mapper::Constraints) && r.app.app.respond_to?(:call)}

    routes.reject! {|r| r.app.is_a?(ActionDispatch::Routing::Redirect)}

    if @app.config.respond_to?(:assets)
      exclusion_regexp = %r{^#{@app.config.assets.prefix}}

      routes.reject! do |route|
        path = (defined?(ActionDispatch::Journey::Route) || defined?(Journey::Route)) ? route.path.spec.to_s : route.path
        path =~ exclusion_regexp
      end
    end
    routes
  end

  def get_helper_modules(subtree = [])
    helper_directory = Rails.root.join('app').join('helpers')
    subtree.each do |folder|
      helper_directory = helper_directory.join(folder)
    end
    entries = Dir.entries(helper_directory) - %w(. ..)
    files = entries.select { |e| e.include?('.rb') }
    modules = files.map do |file|
      module_name = subtree.map(&:camelcase).join('::')
      if module_name.present?
        module_name += '::'
      end
      class_name = file.gsub('.rb', '').camelcase
      (module_name + class_name).constantize
    end
    directores = entries.reject { |e| e.include?('.rb') }
    directores.each do |dir|
      modules.concat get_helper_modules(subtree + [dir])
    end
    modules
  end
end
