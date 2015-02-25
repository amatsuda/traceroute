require_relative 'test_helper'

class TracerouteTest < Minitest::Test
  def setup
    @traceroute = Traceroute.new Rails.application
    @traceroute.load_everything!
  end

  def test_defined_action_methods
    assert_equal ['users#index', 'users#index2', 'users#show', 'admin/shops#index', 'admin/shops#create'], @traceroute.defined_action_methods
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

class TracerouteRakeTests < Minitest::Test
  def setup
    require 'rake'
    load "./lib/tasks/traceroute.rake"
  end

  def test_dont_fail_when_envvar_not_set
    traceroute = Traceroute.new Rails.application
    traceroute.load_everything!

    ENV['FAIL_ON_ERROR'] = ""
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
