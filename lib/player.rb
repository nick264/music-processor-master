class Player
	attr_accessor :player_id

	def initialize(filename)
		reset_log
		@filename = filename

		Signal.trap("EXIT"){ self.stop() }
		Signal.trap("TERM"){ self.stop() }
		Signal.trap("INT"){ self.stop() }
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
		ffplay_available = `type ffplay >/dev/null && echo "found" || echo "not found"`.chomp == "found"
		command = if ffplay_available
			"ffplay"
		else
			"sudo avplay"
		end

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

	def reset_log
		`rm #{log_file}`
	end

	def log_file
		'tmp/log'
	end
end