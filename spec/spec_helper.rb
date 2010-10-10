$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require 'lib/groem'

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'shared', '**', '*.rb'))].each do |f|
  load f
end

Bundler.setup :test
require 'minitest/spec'
MiniTest::Unit.autorun
