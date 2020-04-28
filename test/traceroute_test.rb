# frozen_string_literal: true

require_relative 'test_helper'

module TracerouteTest
  class BasicTest < Minitest::Test
    def setup
      @traceroute = Traceroute.new Rails.application
    end

    def test_defined_action_methods
      assert_defined_action_methods 'users#index', 'users#show', 'users#index2', 'admin/shops#create', 'admin/shops#index', 'api/books#create', 'api/books#index'
    end

    def test_routed_actions
      assert_empty @traceroute.routed_actions
    end
  end

  class RoutedActionsTest < Minitest::Test
    def setup
      DummyApp::Application.routes.draw do
        resources :users, :only => [:index, :show, :new, :create]

        get '/', to: redirect('/users'), constraints: lambda { true }

        namespace :admin do
          resources :shops, :only => :index
        end

        namespace :api do
          resources :books, :only => :index
        end
      end

      @traceroute = Traceroute.new Rails.application
    end

    def teardown
      DummyApp::Application.routes.clear!
    end

    def test_routed_actions
      assert_routed_actions 'admin/shops#index', 'api/books#index', 'users#index', 'users#show', 'users#new', 'users#create'
    end
  end

  class TracerouteRakeTests < Minitest::Test
    def setup
      require 'rake'
      load "./lib/tasks/traceroute.rake"
      @fail_on_error_was = ENV['FAIL_ON_ERROR']
    end

    def teardown
      ENV['FAIL_ON_ERROR'] = @fail_on_error_was
      Rake::Task.clear
      DummyApp::Application.routes.clear!
    end

    def test_rake_task_fails_when_unreachable_action_method_detected
      ENV['FAIL_ON_ERROR']="1"
      Rake::Task[:traceroute].execute
    rescue => e
      assert_includes e.message, "Unused routes or unreachable action methods detected."
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

        namespace :api do
          resources :books, :only => [:index, :create]
        end

        namespace :rails do
          resources :mailers, only: ["index"] do
            member do
              get :preview
            end
          end
        end
      end

      begin
        ENV['FAIL_ON_ERROR'] = "1"
        Rake::Task[:traceroute].execute
      rescue => e
        assert_includes e.message, "Unused routes or unreachable action methods detected."
      end
    end
  end
end
