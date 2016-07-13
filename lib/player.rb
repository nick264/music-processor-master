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

		if system_mpd_running?
			`pkill -9 mpd`
		end

		if !mpd_running?
			`mpd #{mpd_config_filename}`
		end

		@@mpd = MPD.new
		@@mpd.connect
		@@mpd
	end

	def self.mpd_running?
		`ps aux | grep [m]pd | grep #{ROOT_DIR} | grep -v "bash"`.strip.size > 0
	end

	def self.system_mpd_running?
		`ps aux | grep [m]pd | grep -v #{ROOT_DIR} | grep -v "bash"`.strip.size > 0
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
		mpd.status[:elapsed]
		# elapsed_ms = `config/.mpd/mpdtime`.strip

		# if elapsed_ms.present?
		# 	elapsed_ms.to_i / 1e3
		# else
		# 	nil
		# end
	end

	def start_time
		if curpos = current_position
			Time.now - curpos
		else
			nil
		end
	end
end