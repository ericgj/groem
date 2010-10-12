$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))
require 'rubygems'
require 'bundler'
Bundler.setup :development

require 'lib/groem'

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'shared', '**', '*.rb'))].each do |f|
  load f
end

require 'minitest/spec'
MiniTest::Unit.autorun
