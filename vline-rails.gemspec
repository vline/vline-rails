$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "vline/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "vline-rails"
  s.version     = Vline::VERSION
  s.authors     = ["Ben Strong", "Prakash Ramakrishna", "Tom Hughes"]
  s.email       = ["ben@vline.com", "prakash@vline.com", "tom@vline.com"]
  s.homepage    = "https://vline.com"
  s.summary     = "vline plugin for rails"
  s.description = "A plugin that adds support for vline video chat to any rails app."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.9"
  s.add_dependency "grape"
  s.add_dependency "jwt"
  s.add_dependency "rack-jsonp"
end
