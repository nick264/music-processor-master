load "init.rb"

# code goes here
# Signal.trap("EXIT") {
#   @player.stop if @player
# }

youtube_url = ARGV[0]

puts "youtube_url=#{youtube_url}"

filename = YoutubeAudio.fetch!(youtube_url)
chords   = Chordify.fetch!(youtube_url)
@player  = Player.new(filename)
@player.play
ChordStreamer.new(@player,chords).stream


# sleep(2)

# raise "ahh"

# duration = 1
# next_target = nil

# while(true) do
#   curpos = @player.current_position
#   next_target = ( curpos + duration ).to_i
#   puts "Targeting for #{next_target}"

#   sleep(next_target - curpos)

#   puts "Boom!"
#   puts @player.current_position
# end


# # filename = YoutubeAudio.fetch!("https://www.youtube.com/watch?v=b6YWZKfvpho")
# filename = File.join(ROOT_DIR,"cache/b6YWZKfvpho.wav")
# plaything = Plaything.new
# RubyAudio::Sound.open(filename) do |snd| 
#   # snd.info.length
#   # snd.info.frames
#   # snd.info.samplerate
#   # snd.info.main_format
#   snd.seek(15 * snd.info.samplerate) # fast forward 15 seconds

#   buf = nil
#   while buf.nil? || buf.real_size > 0
#     buf = snd.read(:int,10000)

#     # debugger
#     puts "#{buf.real_size}\t#{buf.to_a[0].inspect}"

#     # pcm = buf.to_a.flatten.map{ |x| x / 2**16 }
#     pcm = buf.to_a.flatten

#     # debugger

#     plaything.stream(pcm,sample_type: :int16, sample_rate: snd.info.samplerate, channels: snd.info.channels)
#     # plaything << 
#   end
# end
# # chords = Chordify.fetch!("https://www.youtube.com/watch?v=b6YWZKfvpho")


# require 'coreaudio'
# require 'thread'

# BUFF_SIZE = 1024

# Thread.abort_on_exception = true

# song      = CoreAudio::AudioFile.new("cache/b6YWZKfvpho.wav", :read)
# device    = CoreAudio.default_output_device
# outbuf    = device.output_buffer(BUFF_SIZE)

# queue     = Queue.new

# play_song = Thread.start do
#   while segment = song.read(BUFF_SIZE)
#     # debugger
#     seg_arr = segment.to_a
#     seg_arr = seg_arr.each_with_index.select{ |elem,i| i % 3 != 0 }.map(&:first)
#     segment = NArray.to_na(seg_arr)
#     outbuf << segment
#   end

#   # segment = song.read(BUFF_SIZE)
#   # outbuf << segment
#   # sleep(20)
# end

# outbuf.start
# # sleep 10

# check_buffer = Thread.start do
#   loop do
#     puts device.output_buffer(1024).space
#     # puts outbuf.space
#     puts device.output_stream.buffer_frame_size
#     sleep(1)
#   end
# end

# play_song.join
# check_buffer.join


# portaudio?
# ruby gstreamer bindings?

# require "gst"

# bin = Gst::Pipeline.new("pipeline")
# clock = bin.clock
# src = Gst::ElementFactory.make("audiotestsrc", nil)
# raise "need audiotestsrc from gst-plugins-base" if src.nil?
# sink = Gst::ElementFactory.make("autoaudiosink", nil)
# raise "need autoaudiosink from gst-plugins-good" if sink.nil?

# bin << src << sink
# src >> sink

# # setup control sources
# cs1 = Gst::InterpolationControlSource.new
# cs2 = Gst::InterpolationControlSource.new

# src.add_control_binding(Gst::DirectControlBinding.new(src, "volume", cs1))
# src.add_control_binding(Gst::DirectControlBinding.new(src, "freq", cs2))

# # set interpolation mode
# cs1.mode = Gst::InterpolationMode::LINEAR
# cs2.mode = Gst::InterpolationMode::LINEAR

# # set control values
# cs1.set(0 * Gst::SECOND, 0.0)
# cs1.set(5 * Gst::SECOND, 1.0)

# cs2.set(0 * Gst::SECOND,  220.0 / 20000.0)
# cs2.set(3 * Gst::SECOND, 3520.0 / 20000.0)
# cs2.set(6 * Gst::SECOND,  440.0 / 20000.0)

# # run for 7 seconds
# clock_id = clock.new_single_shot_id(clock.time + (7 * Gst::SECOND))
# bin.play
# wait_ret, jitter = Gst::Clock.id_wait(clock_id)
# $stderr.puts "Clock::id_wait returned: #{wait_ret}" if wait_ret != Gst::ClockReturn::OK
# bin.stop