class ChordStreamer
	def initialize(player, chords)
		@player = player
		@chords = chords

		@event_schedule = @chords.map do |x|
			[ x[2], x[1] == "N" ? nil : x[1] ]
		end

		sleep(1) if @player.current_position.nil?

		@start_time = Time.now - @player.current_position
	end


	def stream
		sync_clock_thread = Thread.start do
			self.sync_clock()
		end

		execute_events_thread = Thread.start do
			while(@event_schedule.size > 0) do
				self.execute_next_event
			end
		end

		execute_events_thread.join
		sync_clock_thread.join
	end 

	def execute_next_event
		next_event = @event_schedule[0]
		next_event_time = @start_time + next_event[0].to_f
		now        = Time.now

		if now > next_event_time
			puts "Skipping event #{next_event[1]}"
		else
			# puts "Going to do next event in #{next_event_time - now}!"
			sleep(next_event_time - now)
			puts "Sending event #{next_event[1].inspect}"
			# send next_event[1]
		end

		@event_schedule = @event_schedule[1..-1]

		true
	end

	def sync_clock
		while(@event_schedule.size > 0) do
			new_start_time = Time.now - @player.current_position
			puts "SYNCING CLOCK: new-old = #{new_start_time - @start_time}"
			@start_time = new_start_time
			sleep(10)
		end
	end
end