# frozen_string_literal: true

require_relative 'test_helper'

module TestEngine
  class Engine < ::Rails::Engine
    isolate_namespace TestEngine
  end

  class TasksController < ApplicationController; end
end

module EngineTestsCondition
  def setup
    TestEngine::TasksController.class_eval { def index() end }
    super
  end

  def teardown
    super
    TestEngine::TasksController.send :undef_method, :index
    TestEngine::TasksController.clear_action_methods!
  end
end

module TracerouteWithEngineTest
  class BasicTest < Minitest::Test
    prepend EngineTestsCondition

    def setup
      @traceroute = Traceroute.new Rails.application
    end

    def test_defined_action_methods
      assert_defined_action_methods 'admin/shops#create', 'admin/shops#index', 'api/books#create', 'api/books#index', 'test_engine/tasks#index', 'users#index', 'users#index2', 'users#show'
    end

    def test_routed_actions
      assert_empty @traceroute.routed_actions
    end
  end

  class RoutedActionsTest < Minitest::Test
    prepend EngineTestsCondition

    def setup
      DummyApp::Application.routes.draw do
        resources :posts, :only => [:index, :show, :new, :create]
      end

      @traceroute = Traceroute.new Rails.application
    end

    def teardown
      DummyApp::Application.routes.clear!
    end

    def test_routed_actions
      assert_routed_actions 'posts#index', 'posts#show', 'posts#new', 'posts#create'
    end
  end

  class EngineTest < Minitest::Test
    prepend EngineTestsCondition

    def setup
      TestEngine::Engine.routes.draw do
        resources :tasks, only: :index
      end

      Rails.application.routes_reloader.route_sets << DummyApp::Application.routes
      DummyApp::Application.routes.draw do
        resources :posts, only: [:index, :show]

        mount TestEngine::Engine => '/test_engine'
      end

      @traceroute = Traceroute.new Rails.application
    end

    def teardown
      DummyApp::Application.routes.clear!
    end

    def test_defined_action_methods
      assert_defined_action_methods 'admin/shops#create', 'admin/shops#index', 'api/books#create', 'api/books#index', 'test_engine/tasks#index', 'users#index', 'users#index2', 'users#show'
    end

    def test_routed_actions
      assert_routed_actions 'posts#index', 'posts#show', 'test_engine/tasks#index'
    end
  end
end
