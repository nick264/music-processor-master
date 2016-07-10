class ChordStreamer

  def initialize(player, chords, arduino_port = nil)
    @player       = player
    @chords       = chords # [ beat, chord, time_start, time_end ]
    @arduino_port = arduino_port || detect_port

    # @colors_hex = ColourLovers.fetch!()
    @colors_hex = [ "FA6900", "69D2E7", "E0E4CC", "FA5A46"]


    chords_to_index = allocate_colors(@chords.map{ |x| x[1] })
    
    @event_schedule = @chords.map do |x|
      [ x[2], x[1], chords_to_index[x[1]] ]
    end
  end

  def stream
    @player.reset_log # so that we sync the clock correctly
    set_palette(@colors_hex)
    sleep(2)

    # double check that everything is set up correctly
    raise "Expect no start time" unless @player.start_time.nil? # start time gets set when player plays
    raise "Expect event schedule!" unless @event_schedule.size > 0

    @player.play
    @execute_events_thread = Thread.new do
      # rapidly sync clock while waiting for player to initialize
      while(@player.start_time.nil?) do
        sleep(0.1)
      end

      # stream the chords
      while(@event_schedule.size > 0) do
        self.execute_next_event
      end
    end

    self
  end

  def stop
    @player.stop() if @player
    @execute_events_thread.kill() if @execute_events_thread
  end

  def wait
    @execute_events_thread.join if @execute_events_thread
  end

  def execute_next_event
    # puts "executing event: #{@event_schedule[0].inspect}"
    next_event = @event_schedule[0]
    next_event_time = @player.start_time(10) + next_event[0].to_f
    now        = Time.now

    if now > next_event_time
      puts "Skipping event #{next_event[1]}"
    else
      # puts "sleeping #{next_event_time - now} until next event"
      sleep(next_event_time - now)
      # puts "Sending event #{next_event.inspect}"
      serial_port.write(next_event[2].chr)
      # serial_port_direct_write(( next_event[2] + 1 ).chr)
      # puts "wrote the event"
    end

    @event_schedule = @event_schedule[1..-1]

    true
  end

  def set_palette(colors_hex)
    colors_rgb = colors_hex.map do |hex|
      hex.match(/(..)(..)(..)/).to_a[1..3].map{ |x| x.to_i(16) }
    end

    command = "p" + colors_rgb.map{ |x| x.join(',') }.join(';') + "|"
    # puts "Sending command: "
    # puts command
    serial_port.write(command)
  end

  def serial_port
    return @serial_port if @serial_port

    port_str  = @arduino_port
    baud_rate = 9600
    data_bits = 8
    stop_bits = 1
    parity    = SerialPort::NONE
 
    @serial_port = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
    sleep(2) # if we try to write too quickly after initialization the bits get lost...
    @serial_port
  end

  def serial_port_direct_write(input)
    return if input.size == 0

    if !@serial_port_configured
      puts `stty -F #{detect_port} speed 9600 cs8 -cstopb -parenb`
      @serial_port_configured = true
    end

    `echo -n '#{input}' > /dev/ttyACM0`
  end

  def allocate_colors(chords)
    all_chords = chords.uniq - [ "N" ]
    # puts "There are #{all_chords.size} chords: #{all_chords.inspect}."

    # find how often certain chords appear together
    collisions = {}
    chords[0..-2].zip(chords[1..-1]).map do |currentEv, nextEv|
      next if currentEv == nextEv
      collision = [currentEv,nextEv].sort
      collisions[collision] ||= 0
      collisions[collision] += 1
    end

    # allocate indexes such that we minimize collisions
    retval = {}
    index = 0

    collisions_sorted = Hash[ collisions.to_a.sort_by(&:last).reverse ]
    # puts "Collisions: "
    # collisions_sorted.each{ |x,y| puts "#{x.inspect}\t#{y}" }

    collisions_sorted.each do |these_chords,count|
      if !retval.key?(these_chords[0])
        retval[these_chords[0]] = index 
        index += 1
      end

      if !retval.key?(these_chords[1])
        retval[these_chords[1]] = index
        index += 1
      end
    end

    # puts "Allocation: "
    # retval.each{ |x,y| puts "#{x.inspect}\t#{y}" }

    remaining_collisions = {}
    retval.to_a.group_by{ |chord,this_index| this_index % 5 }.each do |index_mod,chord_map|
      these_chords = chord_map.map(&:first)
      next if these_chords.size == 1
      for i in 0..(these_chords.size - 1) do
        for j in (i+1)..(these_chords.size - 1) do
          chord_collision = [these_chords[i],these_chords[j]].sort
          remaining_collisions[chord_collision] = collisions[chord_collision] if !collisions[chord_collision].nil?
        end
      end
    end

    # puts "Assuming five colors, remaining collisions: "
    # remaining_collisions.to_a.sort_by(&:last).reverse.each{ |x,y| puts "#{x.inspect}\t#{y}" }

    retval
  end

  def detect_port
    port_config    = YAML.load_file(File.join(ROOT_DIR,'config/serial-ports.yml'))
    matching_ports = port_config.values.flatten.map do |x|
      `ls #{x}`.split("\n")
    end.flatten

    raise "No matching port found!  Please connect the Arduino, specify explicitly or update the serial ports config." if matching_ports.size == 0
    raise "Multiple valid ports found: #{matching_ports.inspect}.  Please specify which one, or update the serial ports config." if matching_ports.size > 1

    puts "DETECTED ARDUINO #{matching_ports[0]}"

    matching_ports[0]
  end
end