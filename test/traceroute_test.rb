require_relative 'test_helper'

class TracerouteTest < Minitest::Test
  def setup
    @traceroute = Traceroute.new Rails.application
    @traceroute.load_everything!
  end

  def test_defined_action_methods
    assert_equal ['users#index', 'users#show', 'users#index2', 'admin/shops#create', 'admin/shops#index', 'jasmine_rails/spec_runner#index'], @traceroute.defined_action_methods
  end

  def test_routed_actions
    assert_empty @traceroute.routed_actions
  end
end

class RoutedActionsTest < Minitest::Test
  def setup
    DummyApp::Application.routes.draw do
      resources :users, :only => [:index, :show, :new, :create]

      namespace :admin do
        resources :shops, :only => :index
      end
    end

    @traceroute = Traceroute.new Rails.application
  end

  def teardown
    DummyApp::Application.routes.clear!
  end

  def test_routed_actions
    assert_equal ['admin/shops#index', 'users#index', 'users#show', 'users#new', 'users#create'].sort, @traceroute.routed_actions.sort
  end
end

class DotFileTest < Minitest::Test
  def setup
    File.open ".traceroute.yaml", "w" do |file|
      file.puts 'ignore_unreachable_actions:'
      file.puts '- ^jasmine_rails\/'
      file.puts 'ignore_unused_routes:'
      file.puts '- ^users'
    end

    DummyApp::Application.routes.draw do
      resources :users, :only => [:index, :show, :new, :create]

      namespace :admin do
        resources :shops, :only => :index
      end
    end

    @traceroute = Traceroute.new Rails.application
    @traceroute.load_everything!
  end

  def teardown
    DummyApp::Application.routes.clear!

    File.delete ".traceroute.yaml"
  end

  def test_unreachable_actions_are_ignored
    refute @traceroute.defined_action_methods.include? 'jasmine_rails/spec_runner#index'
  end

  def test_used_routes_are_ignored
    assert_equal ['admin/shops#index'].sort, @traceroute.routed_actions.sort
  end
end

class EmptyFileTest < Minitest::Test
  def setup
    File.open ".traceroute.yaml", "w" do |file|
    end

    DummyApp::Application.routes.draw do
      resources :users, :only => [:index, :show, :new, :create]

      namespace :admin do
        resources :shops, :only => :index
      end
    end

    @traceroute = Traceroute.new Rails.application
    @traceroute.load_everything!
  end

  def teardown
    DummyApp::Application.routes.clear!

    File.delete ".traceroute.yaml"
  end

  def test_empty_yaml_file_is_handled_the_same_as_no_file
    assert_equal ['users#index', 'users#show', 'users#index2', 'admin/shops#create', 'admin/shops#index', 'jasmine_rails/spec_runner#index'], @traceroute.defined_action_methods
  end

  def test_property_with_no_key
    assert_equal ['admin/shops#index', 'users#index', 'users#show', 'users#new', 'users#create'].sort, @traceroute.routed_actions.sort
  end
end

class InvalidFileTest < Minitest::Test
  def setup
    File.open ".traceroute.yml", "w" do |file|
      file.puts 'ignore_unreachable_actions:'
      file.puts 'ignore_unused_routes:'
    end

    DummyApp::Application.routes.draw do
      resources :users, :only => [:index, :show, :new, :create]

      namespace :admin do
        resources :shops, :only => :index
      end
    end

    @traceroute = Traceroute.new Rails.application
    @traceroute.load_everything!
  end

  def teardown
    DummyApp::Application.routes.clear!

    File.delete ".traceroute.yml"
  end

  def test_empty_yaml_file_is_handled_the_same_as_no_file
    assert_equal ['users#index', 'users#show', 'users#index2', 'admin/shops#create', 'admin/shops#index', 'jasmine_rails/spec_runner#index'], @traceroute.defined_action_methods
  end

  def test_property_with_no_key
    assert_equal ['admin/shops#index', 'users#index', 'users#show', 'users#new', 'users#create'].sort, @traceroute.routed_actions.sort
  end
end

class FilenameSupportTest < Minitest::Test
  def test_yml_supported
    File.open ".traceroute.yml", "w" do |file|
      file.puts 'ignore_unreachable_actions:'
      file.puts '- ^jasmine_rails\/'
      file.puts 'ignore_unused_routes:'
      file.puts '- ^users'
    end

    @traceroute = Traceroute.new Rails.application
    @traceroute.load_everything!

    refute @traceroute.defined_action_methods.include? 'jasmine_rails/spec_runner#index'

    File.delete ".traceroute.yml"
  end

  def test_no_extension_supported
    File.open ".traceroute", "w" do |file|
      file.puts 'ignore_unreachable_actions:'
      file.puts '- ^jasmine_rails\/'
      file.puts 'ignore_unused_routes:'
      file.puts '- ^users'
    end

    @traceroute = Traceroute.new Rails.application
    @traceroute.load_everything!

    refute @traceroute.defined_action_methods.include? 'jasmine_rails/spec_runner#index'

    File.delete ".traceroute"
  end
end

class TracerouteRakeTests < Minitest::Test
  def setup
    require 'rake'
    load "./lib/tasks/traceroute.rake"
  end

  def test_dont_fail_when_envvar_is_anything_but_1
    traceroute = Traceroute.new Rails.application
    traceroute.load_everything!

    ENV['FAIL_ON_ERROR'] = "DERP"
    Rake::Task[:traceroute].execute
  end

  def test_rake_task_fails_when_unreachable_action_method_detected
    traceroute = Traceroute.new Rails.application
    traceroute.load_everything!

    begin
      ENV['FAIL_ON_ERROR']="1"
      Rake::Task[:traceroute].execute
    rescue => e
      assert_includes e.message, "Unused routes or unreachable action methods detected."
    end
  end

  def test_rake_task_fails_when_unused_route_detected
    DummyApp::Application.routes.draw do
      resources :users, :only => [:index, :show, :new, :create] do
        member do
          get :index2
        end
      end

      namespace :admin do
        resources :shops, :only => [:index, :create]
      end

      namespace :rails do
        resources :mailers, only: ["index"] do
          member do
            get :preview
          end
        end
      end
    end

    traceroute = Traceroute.new Rails.application

    begin
      ENV['FAIL_ON_ERROR'] = "1"
      Rake::Task[:traceroute].execute
    rescue => e
      assert_includes e.message, "Unused routes or unreachable action methods detected."
    end
  end

  def teardown
    Rake::Task.clear
    DummyApp::Application.routes.clear!
  end
end
