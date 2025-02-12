load File.join(File.expand_path(File.dirname(__FILE__)),'init.rb')

# code goes here
# Signal.trap("EXIT") {
#   @player.stop if @player
# }

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: start.rb [options]"

  opts.on("-y", "--yt YOUTUBE_URL", "Youtube url to use") do |url|
    options[:youtube_url] = url
    puts "SET youtube url TO #{options[:youtube_url]}"
  end

  opts.on("-p", "--port ARDUINO_PORT", "Location of Arduino port",  "e.g. /dev/tty.usbmodem4") do |port|
    options[:arduino_port] = port
    puts "SET arduino port TO #{options[:arduino_port]}"
  end
end.parse!


if options[:youtube_url].nil?
	key = Chordify.choose_from_library
	options[:youtube_url] = "https://www.youtube.com/watch?v=#{key}"
end

ChordStreamer.init_serial_port # to make data write faster once we select a song
Chordify.library # load chordify library

filename = YoutubeAudio.fetch!(options[:youtube_url])
chords   = Chordify.fetch!(options[:youtube_url])
@player  = Player.new(filename)
@streamer = ChordStreamer.new(@player,chords).stream
@streamer.wait