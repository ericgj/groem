# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'groem/version'

Gem::Specification.new do |s|
  s.name         = "groem"
  s.version      = Groem::VERSION
  s.authors      = ["Eric Gjertsen"]
  s.email        = "ericgj72@gmail.com"
  s.homepage     = "http://github.com/ericgj/groem"
  s.summary      = "Eventmachine-based Growl (GNTP) client"
  s.description  = ""

  s.files        = `git ls-files app lib`.split("\n")
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'
  s.required_rubygems_version = '>= 1.3.6'
end
