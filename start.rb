load "init.rb"

# code goes here

# filename = YoutubeAudio.fetch!("https://www.youtube.com/watch?v=b6YWZKfvpho")
filename = File.join(ROOT_DIR,"cache/b6YWZKfvpho.wav")
buf = nil;RubyAudio::Sound.open(filename) { |snd| 1000.times.each{ buf = snd.read(:float,1000); puts "#{buf.real_size}\t#{buf.to_a.flatten.max}"; plaything << buf.to_a.map{ |x| ( x[0] + x[1] ) } } }
# chords = Chordify.fetch!("https://www.youtube.com/watch?v=b6YWZKfvpho")

