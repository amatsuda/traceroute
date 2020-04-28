# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "traceroute"
  s.version     = '0.8.1'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Akira Matsuda']
  s.email       = ['ronnie@dio.jp']
  s.homepage    = 'https://github.com/amatsuda/traceroute'
  s.summary     = 'A Rake task that helps you find the dead routes and actions for your Rails 3 app'
  s.description =  "This Rake task investigates the application's routes definition, then tells you unused routes and unreachable action methods"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.extra_rdoc_files = ['README.rdoc']
  s.require_paths = ['lib']

  s.licenses = ['MIT']

  s.add_dependency 'rails', ['>= 3.0.0']
end
