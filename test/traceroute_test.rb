require_relative 'test_helper'

class TracerouteTest < Minitest::Test
  def setup
    @traceroute = Traceroute.new Rails.application
    @traceroute.load_everything!
  end

  def test_defined_action_methods
    assert_equal ['users#index', 'users#index2', 'users#show', 'admin/shops#index', 'admin/shops#create'], @traceroute.defined_action_methods.reject {|r| r.start_with? 'rails/'}
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
    assert_equal ['admin/shops#index', 'users#index', 'users#show', 'users#new', 'users#create'].sort, @traceroute.routed_actions.reject {|r| r.start_with? 'rails/'}.sort
  end
end
