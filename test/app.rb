require 'rails'
require 'action_controller/railtie'

require 'traceroute'

ActionController::Base.append_view_path 'test/views'

module DummyApp
  class Application < Rails::Application
    config.root = File.expand_path('..', __FILE__)
    config.eager_load = false
    config.secret_key_base = '1234567890'
  end
end

class ApplicationController < ActionController::Base; end

class UsersController < ApplicationController
  def index; end
  def index2; end
  def show; end
end

module Admin; class ShopsController < ApplicationController
  def index; end
  def create; end
end; end

module JasmineRails; class SpecRunner < ApplicationController
  def index; end
end; end

DummyApp::Application.initialize!
