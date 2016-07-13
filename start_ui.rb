load 'init.rb'
ChordStreamer.init_serial_port # for faster streamer on input selection
Input.new(true).monitor
# Input.new(false).monitor