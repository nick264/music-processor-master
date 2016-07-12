require 'active_support/core_ext/string'

class Player
	MPD_DIR = 'config/.mpd'
	CACHE_DIR = "cache"
	@@mpd ||= nil

	def self.setup_mpd_config
		File.open(mpd_config_filename,'w') do |f|
			f.write <<-EOS.strip_heredoc
				music_directory         "#{File.join(ROOT_DIR,CACHE_DIR)}"
				playlist_directory      "#{File.join(ROOT_DIR,MPD_DIR,"playlists")}"
				db_file                 "#{File.join(ROOT_DIR,MPD_DIR,"mpd.db")}"
				log_file                "#{File.join(ROOT_DIR,MPD_DIR,"mpd.log")}"
				pid_file                "#{File.join(ROOT_DIR,MPD_DIR,"mpd.pid")}"
				state_file              "#{File.join(ROOT_DIR,MPD_DIR,"mpdstate")}"
				auto_update             "yes"
				auto_update_depth       "2"
				follow_outside_symlinks "yes"
				follow_inside_symlinks  "yes"

				decoder {
				  plugin                "mp4ff"
				  enabled               "no"
				}

				bind_to_address         "127.0.0.1"
				port                    "6600"
			EOS
		end
	end

	def self.mpd_config_filename
		File.join(ROOT_DIR,MPD_DIR,'mpd.conf')
	end

	def self.init_mpd
		self.setup_mpd_config if !File.exists?(self.mpd_config_filename)

		if @@mpd
			@@mpd.reconnect if !@@mpd.connected?
			return @@mpd
		end

		if !mpd_running?
				`mpd #{mpd_config_filename}`
		end

		@@mpd = MPD.new
		@@mpd.connect
		@@mpd
	end

	def self.mpd_running?
		`ps aux | grep [m]pd`.strip.size > 0
	end

	def mpd
		self.class.init_mpd
	end

	def initialize(filename)
		Signal.trap('EXIT'){ Thread.new{ self.stop() } }
		Signal.trap('INT'){ Thread.new{ self.stop() } }
		Signal.trap('TERM'){ Thread.new{ self.stop() } }

		@filename = File.split(filename).last

		puts @filename

		# clear the queue
		mpd.queue.size.times.each{ mpd.delete(0) }

		# add to the queue
		mpd.add(@filename)
	end

	def play
		mpd.play
	end

	def pause
		mpd.pause
	end

	def stop
		mpd.stop
	end

	def current_position
		status = mpd.status

		if status[:state] == :play
			status[:elapsed] - 0.0
		else
			nil
		end
	end

	def start_time
		if curpos = current_position
			Time.now - curpos
		else
			nil
		end
	end

	# def initialize(filename)
	# 	reset_log
	# 	@filename = filename

	# 	# Signal.trap("EXIT"){ self.stop() }
	# 	# Signal.trap("TERM"){ self.stop() }
	# 	# Signal.trap("INT"){ self.stop() }
	# end

	# def current_position
	# 	return nil if !File.exists?(log_file)
	# 	contents = File.open(log_file).read
	# 	return nil if contents.size == 0

	#   contents.split("\r").last.strip.split(" ").first.to_f
	# end

	# def start_time(sync_after = nil)
	# 	return @start_time if sync_after && @last_synced && Time.now < @last_synced + sync_after
	# 	return nil if current_position.nil?
		
	# 	now = Time.now
	# 	new_start_time = now - current_position
	# 	puts "SYNCING CLOCK: new-old = #{new_start_time - @start_time}" if @start_time
	# 	@last_synced = now
	# 	@start_time = new_start_time
	# end

	# def play
	# 	ffplay_available = `type ffplay >/dev/null && echo "found" || echo "not found"`.chomp == "found"
	# 	command = if ffplay_available
	# 		"ffplay"
	# 	else
	# 		"sudo avplay"
	# 	end

	#   @player_id = fork do
	#     exec("#{command} -i -nodisp #{@filename}", out: [log_file,'w'], err: [log_file,'w'])
	#   end
	# end

	# def stop
	# 	return if !@player_id

	# 	puts "killing process..."

	# 	Process.kill("TERM",@player_id)

	# 	reset_log
	# 	@start_time = nil
	# 	@last_synced = nil
	# end

	# def reset_log
	# 	`rm #{log_file}`
	# end

	# def log_file
	# 	'tmp/log'
	# end
end