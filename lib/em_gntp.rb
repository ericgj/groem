$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'bundler'
Bundler.setup :default
require 'lib/em_gntp/marshal'
require 'lib/em_gntp/client'
require 'lib/em_gntp/notification'
require 'lib/em_gntp/app'