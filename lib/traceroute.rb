# coding: utf-8
# frozen_string_literal: true

class Traceroute
  VERSION = Gem.loaded_specs['traceroute'].version.to_s

  WILDCARD_ROUTES = %r[^/?:controller\(?/:action].freeze

  class Railtie < ::Rails::Railtie
    rake_tasks do
      load File.join(File.dirname(__FILE__), 'tasks/traceroute.rake')
    end
  end

  def initialize(app)
    @app = app

    @ignored_unreachable_actions = []
    @ignored_unused_routes = [/^\/cable$/]

    @ignored_unused_routes << %r{^#{@app.config.assets.prefix}} if @app.config.respond_to? :assets

    config_filename = %w(.traceroute.yaml .traceroute.yml .traceroute).detect {|f| File.exist?(f)}
    if config_filename && (config = YAML.load_file(config_filename))
      (config['ignore_unreachable_actions'] || []).each do |ignored_action|
        @ignored_unreachable_actions << Regexp.new(ignored_action)
      end

      (config['ignore_unused_routes'] || []).each do |ignored_action|
        @ignored_unused_routes << Regexp.new(ignored_action)
      end
    end
  end

  def load_everything!
    @app.eager_load!
    ::Rails::InfoController rescue NameError
    ::Rails::WelcomeController rescue NameError
    ::Rails::MailersController rescue NameError
    @app.reload_routes!

    Rails::Engine.subclasses.each(&:eager_load!)
  end

  def unused_routes
    routed_actions - defined_action_methods
  end

  def unreachable_action_methods
    defined_action_methods - routed_actions
  end

  def defined_action_methods
    @defined_action_methods ||= [ActionController::Base, (ActionController::API if defined?(ActionController::API))].compact.map do |klass|
      klass.descendants.map do |controller|
        controller.action_methods.reject {|a| (a =~ /\A(_conditional)?_callback_/) || (a == '_layout_from_proc')}.map do |action|
          "#{controller.controller_path}##{action}"
        end
      end.flatten
    end.flatten.reject {|r| @ignored_unreachable_actions.any? { |m| r.match(m) } }
  end

  def routed_actions
    @routed_actions ||= routes.map do |r|
      if r.requirements[:controller].present? && r.requirements[:action].present?
        "#{r.requirements[:controller]}##{r.requirements[:action]}"
      elsif (String === r.path) && (WILDCARD_ROUTES =~ r.path)
        %Q["#{r.path}"  ⚠️  This is a legacy wild controller route that's not recommended for RESTful applications.]
      elsif WILDCARD_ROUTES =~ r.path.spec.to_s
        %Q["#{r.path.spec}"  ⚠️  This is a legacy wild controller route that's not recommended for RESTful applications.]
      else
        ((String === r.path) && r.path.to_s) || r.path.spec.to_s  # unknown routes
      end
    end.compact.flatten.reject {|r| @ignored_unused_routes.any? { |m| r.match(m) } }
  end

  def routes
    collect_routes @app.routes.routes
  end

  def collect_routes(routes)
    routes = routes.each_with_object([]) do |r, tmp_routes|
      next if (ActionDispatch::Routing::Mapper::Constraints === r.app) && (%w[ActionDispatch::Routing::PathRedirect ActionDispatch::Routing::Redirect].include?(r.app.app.class.name))

      if r.app.is_a?(ActionDispatch::Routing::Mapper::Constraints) && r.app.app.respond_to?(:routes)
        engine_routes = r.app.app.routes
        if engine_routes.is_a?(ActionDispatch::Routing::RouteSet)
          tmp_routes.concat collect_routes(engine_routes.routes)
        end
      else
        tmp_routes << r
      end
    end

    routes.reject! {|r| r.app.is_a?(ActionDispatch::Routing::Redirect)}

    routes
  end
end
