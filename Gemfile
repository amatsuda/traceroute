# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in traceroute.gemspec
gemspec

if ENV['RAILS_VERSION'] == 'edge'
  gem 'rails', git: 'https://github.com/rails/rails.git'
elsif ENV['RAILS_VERSION']
  gem 'rails', "~> #{ENV['RAILS_VERSION']}.0"
else
  gem 'rails'
end
