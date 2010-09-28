$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require 'lib/em_gntp'
Bundler.setup :test
require 'minitest/spec'
MiniTest::Unit.autorun
