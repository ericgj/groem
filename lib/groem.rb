$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'bundler'
Bundler.setup :default
require 'lib/groem/constants'
require 'lib/groem/marshal'
require 'lib/groem/client'
require 'lib/groem/response'
require 'lib/groem/route'
require 'lib/groem/notification'
require 'lib/groem/app'