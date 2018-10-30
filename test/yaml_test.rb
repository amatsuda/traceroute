# frozen_string_literal: true

require_relative 'test_helper'

module JasmineRails
  class SpecRunner < ApplicationController; end
end

module YamlTestsCondition
  def setup
    super
    JasmineRails::SpecRunner.class_eval { def index() end }
  end

  def teardown
    super
    JasmineRails::SpecRunner.send :undef_method, :index
    JasmineRails::SpecRunner.clear_action_methods!
  end
end

class DotFileTest < Minitest::Test
  prepend YamlTestsCondition

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

      namespace :api do
        resources :books, :only => :index
      end
    end

    @traceroute = Traceroute.new Rails.application
  end

  def teardown
    DummyApp::Application.routes.clear!

    File.delete ".traceroute.yaml"
  end

  def test_unreachable_actions_are_ignored
    refute @traceroute.defined_action_methods.include? 'jasmine_rails/spec_runner#index'
  end

  def test_used_routes_are_ignored
    assert_routed_actions 'admin/shops#index', 'api/books#index'
  end
end

class EmptyFileTest < Minitest::Test
  prepend YamlTestsCondition

  def setup
    File.open ".traceroute.yaml", "w" do |file|
    end

    DummyApp::Application.routes.draw do
      resources :users, :only => [:index, :show, :new, :create]

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

    File.delete ".traceroute.yaml"
  end

  def test_empty_yaml_file_is_handled_the_same_as_no_file
    assert_defined_action_methods 'users#index', 'users#show', 'users#index2', 'admin/shops#create', 'admin/shops#index', 'api/books#create', 'api/books#index', 'jasmine_rails/spec_runner#index'
  end

  def test_property_with_no_key
    assert_routed_actions 'admin/shops#index', 'api/books#index', 'users#index', 'users#show', 'users#new', 'users#create'
  end
end

class InvalidFileTest < Minitest::Test
  prepend YamlTestsCondition

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

      namespace :api do
        resources :books, :only => :index
      end
    end

    @traceroute = Traceroute.new Rails.application
  end

  def teardown
    DummyApp::Application.routes.clear!

    File.delete ".traceroute.yml"
  end

  def test_empty_yaml_file_is_handled_the_same_as_no_file
    assert_defined_action_methods 'users#index', 'users#show', 'users#index2', 'admin/shops#create', 'admin/shops#index', 'api/books#create', 'api/books#index', 'jasmine_rails/spec_runner#index'
  end

  def test_property_with_no_key
    assert_routed_actions 'admin/shops#index', 'api/books#index', 'users#index', 'users#show', 'users#new', 'users#create'
  end
end

class FilenameSupportTest < Minitest::Test
  prepend YamlTestsCondition

  def test_yml_supported
    File.open ".traceroute.yml", "w" do |file|
      file.puts 'ignore_unreachable_actions:'
      file.puts '- ^jasmine_rails\/'
      file.puts 'ignore_unused_routes:'
      file.puts '- ^users'
    end

    @traceroute = Traceroute.new Rails.application

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

    refute @traceroute.defined_action_methods.include? 'jasmine_rails/spec_runner#index'

    File.delete ".traceroute"
  end
end
