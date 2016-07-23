load File.join(File.expand_path(File.dirname(__FILE__)),'init.rb')
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: start_ui.rb [options]"

  opts.on("-s", "--sfx", "Run with sound effects") do |url|
    options[:sfx] = true
    puts "Sound effects are ON"
  end
end.parse!

ChordStreamer.init_serial_port # for faster streamer on input selection
Chordify.library # load chordify library
Input.new(options[:sfx]).monitor
# Input.new(false).monitor