require "rubygems"
require "bundler/setup"

Bundler.require

ROOT_DIR = Dir.pwd

# load classes
Dir.entries(File.join(ROOT_DIR,"lib")).each{ |x| next if x.start_with?('.'); load(File.join(ROOT_DIR,"lib",x)) }
