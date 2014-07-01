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
end
