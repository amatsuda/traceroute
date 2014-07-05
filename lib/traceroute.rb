module Traceroute
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load File.join(File.dirname(__FILE__), 'tasks/traceroute.rake')
    end
  end

  def self.load_everything!
    Rails.application.eager_load!
    ::Rails::InfoController rescue NameError
    ::Rails::WelcomeController rescue NameError
    ::Rails::MailersController rescue NameError
    Rails.application.reload_routes!

    Rails::Engine.subclasses.each(&:eager_load!)
  end

  def self.routes
    routes = Rails.application.routes.routes.reject {|r| r.name.nil? && r.requirements.blank?}

    routes.reject! {|r| r.app.is_a?(ActionDispatch::Routing::Mapper::Constraints) && r.app.app.respond_to?(:call)}

    if Rails.application.config.respond_to?(:assets)
      exclusion_regexp = %r{^#{Rails.application.config.assets.prefix}}

      routes.reject! do |route|
        path = (defined?(ActionDispatch::Journey::Route) || defined?(Journey::Route)) ? route.path.spec.to_s : route.path
        path =~ exclusion_regexp
      end
    end
    routes
  end
end
