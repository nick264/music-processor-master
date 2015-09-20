class Player
	def initialize(filename)
		@filename = filename

		Signal.trap("EXIT"){ self.stop() }
	end

	def current_position
		return nil if !File.exists?('/tmp/log')
		contents = File.open('/tmp/log').read
		return nil if contents.size == 0

	  contents.split("\r").last.strip.split(" ").first.to_f
	end

	def play
	  @player_id = fork do
	    exec("ffplay -i -nodisp #{@filename}", out: ['/tmp/log','w'], err: ['/tmp/log','w'])
	  end
	end

	def stop
		return if !@player_id

		Process.kill("TERM",@player_id)
		`rm /tmp/log`
	end
end