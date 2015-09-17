require "rubygems"
require "bundler/setup"

Bundler.require

# load classes
Dir.entries("./lib").each{ |x| next if x.start_with?('.'); load("./lib/#{x}") }
