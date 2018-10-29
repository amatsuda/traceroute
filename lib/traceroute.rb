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
    load_ignored_regex!
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
    [ActionController::Base, (ActionController::API if defined?(ActionController::API))].compact.map do |klass|
      klass.descendants.map do |controller|
        controller.action_methods.reject {|a| (a =~ /\A(_conditional)?_callback_/) || (a == '_layout_from_proc')}.map do |action|
          "#{controller.controller_path}##{action}"
        end
      end.flatten
    end.flatten.reject {|r| @ignored_unreachable_actions.any? { |m| r.match(m) } }
  end

  def routed_actions
    routes.map do |r|
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
  def filenames
    [".traceroute.yaml", ".traceroute.yml", ".traceroute"].select { |filename|
      File.exist? filename
    }.select { |filename|
      YAML.load_file(filename)
    }
  end

  def at_least_one_file_exists?
    return !filenames.empty?
  end

  def ignore_config
    filenames.each do |filename|
      return YAML.load_file(filename)
    end
  end

  def load_ignored_regex!
    @ignored_unreachable_actions = [/^rails\//]
    @ignored_unused_routes = [/^rails\//, /^\/cable$/]

    @ignored_unused_routes << %r{^#{@app.config.assets.prefix}} if @app.config.respond_to? :assets

    return unless at_least_one_file_exists?

    if ignore_config.has_key? 'ignore_unreachable_actions'
      unless ignore_config['ignore_unreachable_actions'].nil?
        ignore_config['ignore_unreachable_actions'].each do |ignored_action|
          @ignored_unreachable_actions << Regexp.new(ignored_action)
        end
      end
    end

    if ignore_config.has_key? 'ignore_unused_routes'
      unless ignore_config['ignore_unused_routes'].nil?
        ignore_config['ignore_unused_routes'].each do |ignored_action|
          @ignored_unused_routes << Regexp.new(ignored_action)
        end
      end
    end
  end

  def routes
    collect_routes @app.routes.routes
  end

  def collect_routes(routes)
    routes = routes.each_with_object([]) do |r, tmp_routes|
      next if (ActionDispatch::Routing::Mapper::Constraints === r.app) && (ActionDispatch::Routing::PathRedirect === r.app.app)

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
