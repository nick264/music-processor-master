class Input
  require 'pi_piper'
  # include PiPiper

  BUTTON_PINS_ROW = [21,20,16,12]
  BUTTON_PINS_COL = [6, 13,19,26]

  BUTTONS = [
    [1, 2, 3, 4 ],
    [5, 6, 7, 8 ],
    [9, 10,11,12],
    [13,14,15,16]
  ]

  def initialize(with_sound_fx = false)
    release_pins # sometimes PiPiper doesn't release pins on previous termination, so we make sure they're clear here

    ( @sound_fx_player = Player.new('config/jukebox-sound.mp4'); @sound_fx_player.init_length ) if with_sound_fx

    # Signal.trap("EXIT"){ puts "releasing pins..."; release_pins() }
    # Signal.trap("TERM"){ puts "releasing pins..."; release_pins() }
    # Signal.trap("INT"){ puts "releasing pins..."; release_pins() }
  end

  def release_pins
    ( BUTTON_PINS_ROW + BUTTON_PINS_COL ).each do |pin|
      `echo #{pin} >/sys/class/gpio/unexport`
    end
  end

  def run_show(number)
    selection = Chordify.library.to_a[number-1]
    title = selection[1][:title]
    filename = File.join(ROOT_DIR,"cache","#{selection[0]}.aac")
    youtube_url = "https://www.youtube.com/watch?v=#{selection[0]}"

    chords   = Chordify.fetch!(youtube_url)
    @player  = Player.new(filename)
    streamer = ChordStreamer.new(@player,chords).stream
    streamer
  end

  def monitor
    ChordStreamer.init_serial_port # for faster streamer on input selection

    @running_streamer = nil # track thread and which show it is

    puts "READY FOR INPUT!"

    monitor_keypad do |button_pressed|
      # do nothing if the show is already running.  sometimes we get a bit of a button 'bounce'
      if @running_streamer && @running_streamer[0] == button_pressed
        puts "Already running; doing nothing"
        next
      end

      # kill any currently running shows
      if @running_streamer
        puts "Killing show #{@running_streamer[0]}"
        @running_streamer[1].stop
      end

      # launch the show (unless user hit stop button)
      if button_pressed == 16
        puts "Stopping"
        @running_streamer = nil
      else
        puts "Launching show..."
        if @sound_fx_player
          @sound_fx_player.play
          sleep(@sound_fx_player.length)
        end

        @running_streamer = [ button_pressed, run_show(button_pressed) ]

        @sound_fx_player.stop if @sound_fx_player # make sure to terminate avplayer
      end
    end
  end

  def monitor_keypad(&block)
    @current_high_col = 0

    # monitor row pins
    BUTTONS.each_with_index do |row,row_index|
      PiPiper.after pin: BUTTON_PINS_ROW[row_index], direction: :in, pull: :down, goes: :high do |pin|
        puts "Pin went high!"
        puts "current_high_col = #{@current_high_col}"
        puts "BUTTON #{BUTTONS[row_index][@current_high_col]} was pushed"

        block.call(BUTTONS[row_index][@current_high_col]) if block_given?
      end
    end

    # send rotating signal rotate through col pins

    # set all to low
    col_pins = BUTTON_PINS_COL.map{ |pin_number| PiPiper::Pin.new(pin: pin_number, direction: :out) }
    col_pins.each{ |pin| pin.off }

    Thread.new do
      while(true)
        col_pins.each_with_index do |col_pin,col_index|
          @current_high_col = col_index      
          col_pin.on
          sleep(0.05)
          col_pin.off
          @current_high_col = nil
        end
      end
    end

    PiPiper.wait
  end

  # def set_light(light_number)
  #   lights = [
  #     [1,2],
  #     [3,4]
  #   ]

  #   row_pins = [7,8]
  #   col_pins = [9,10]

  
  #   @rows = row_pins.map{ |p| PiPiper::Pin.new(pin: p, direction: :out) } if !@rows
  #   @cols = col_pins.map{ |p| PiPiper::Pin.new(pin: p, direction: :out) } if !@cols

  #   @rows.each{ |p| p.off }
  #   @cols.each{ |p| p.off }


  #   idx = lights.flatten.index(light_number)
  #   row_idx = idx / lights[0].size
  #   col_idx = idx % lights[0].size

  #   puts row_idx
  #   puts col_idx

  #   @rows[row_idx].on
  #   @cols[col_idx].on
  # end
end