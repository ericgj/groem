$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))
require 'rubygems'
require 'bundler'
Bundler.setup :default

require 'lib/groem'

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'shared', '**', '*.rb'))].each do |f|
  load f
end

Bundler.setup :development
require 'minitest/spec'
MiniTest::Unit.autorun
