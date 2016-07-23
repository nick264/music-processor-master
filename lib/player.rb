require 'digest/sha1'

class Player
	attr_accessor :player_id
	attr_accessor :length

	def initialize(filename)
		@filename = filename
		reset_log

		# Signal.trap("EXIT"){ self.stop() }
		# Signal.trap("TERM"){ self.stop() }
		# Signal.trap("INT"){ self.stop() }
	end

	def current_position
		return nil if !File.exists?(log_file)
		contents = File.open(log_file).read
		return nil if contents.size == 0

	  contents.split("\r").last.strip.split(" ").first.to_f
	end

	def start_time(sync_after = nil)
		return @start_time if sync_after && @last_synced && Time.now < @last_synced + sync_after
		return nil if current_position.nil?
		
		now = Time.now
		new_start_time = now - current_position
		puts "SYNCING CLOCK: new-old = #{new_start_time - @start_time}" if @start_time
		@last_synced = now
		@start_time = new_start_time
	end

	def play
		command = command_available('ffplay') ? "ffplay" : "sudo avplay"

	  @player_id = fork do
	    exec("#{command} -i -nodisp #{@filename}", out: [log_file,'w'], err: [log_file,'w'])
	  end
	end

	def stop
		return if !@player_id

		puts "killing process..."

		Process.kill("TERM",@player_id)

		reset_log
		@start_time = nil
		@last_synced = nil
	end

	def init_length
		return @length if @length

		puts @filename

		if command_available('avconv')
			file_info = `avconv -i #{@filename} 2>&1`
		else
			file_info = `ffmpeg -i #{@filename} 2>&1`
		end

		file_info_split = file_info.split(" ")
		@length = file_info_split[file_info_split.index("Duration:")+1].gsub(",","").split(":").reverse.each_with_index.map{ |x,i| x.to_f * 60 **i }.inject{ |x,y| x +=y }
	end

	def reset_log
		`rm #{log_file}`
	end

	def log_file
		return @log_file if @log_file
		@log_file = "tmp/log-#{Digest::SHA1.hexdigest(@filename)[0..7]}"
	end

	def command_available(command)
		`type #{command} >/dev/null && echo "found" || echo "not found"`.chomp == "found"
	end
end