class Input
  require 'pi_piper'
  # include PiPiper

  PINS_ROW = [21,20,16,12]
  PINS_COL = [6, 13,19,26]

  BUTTONS = [
    [1, 2, 3, 4 ],
    [5, 6, 7, 8 ],
    [9, 10,11,12],
    [13,14,15,16]
  ]

  def initialize
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
    @running_streamer = nil # track thread and which show it is

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
      if button_pressed != 16
        puts "Launching show..."
        @running_streamer = [ button_pressed, run_show(button_pressed) ]
      end
    end
  end

  def monitor_keypad(&block)
    @current_high_col = 0

    # monitor row pins
    BUTTONS.each_with_index do |row,row_index|
      PiPiper.after pin: PINS_ROW[row_index], direction: :in, pull: :down, goes: :high do |pin|
        puts "Pin went high!"
        puts "current_high_col = #{@current_high_col}"
        puts "BUTTON #{BUTTONS[row_index][@current_high_col]} was pushed"

        block.call(BUTTONS[row_index][@current_high_col]) if block_given?
      end
    end

    # send rotating signal rotate through col pins

    # set all to low
    col_pins = PINS_COL.map{ |pin_number| PiPiper::Pin.new(pin: pin_number, direction: :out) }
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

  # def watch4
  #   button_col = 0
  #   button_row = 3

  #   require 'pi_piper'
  #   PiPiper.after pin: PINS_ROW[button_row], direction: :in, pull: :down, goes: :high do |pin|
  #     puts "Pin went high!"
  #     puts "BUTTON #{BUTTONS[button_row][button_col]} was pushed"
  #   end

  #   pin = PiPiper::Pin.new(:pin => PINS_COL[button_col], :direction => :out)
  #   pin.on

  #   PiPiper.wait
  # end

  # def watch3
  #   require 'pi_piper'

  #   PiPiper.watch pin: 27, direction: :in, pull: :down do |pin|
  #     puts "last_value = #{pin.last_value}"
  #     puts "value = #{pin.value}"
  #     # puts "read = #{pin.read}"
  #   end

  #   PiPiper.after pin: 27, direction: :in, pull: :down, goes: :high do |pin|
  #     puts "Pin went high!"
  #   end

  #   output_pin = PiPiper::Pin.new(:pin => 17, :direction => :out)

  # end

  # def watch2
  #   input_pin = PiPiper::Pin.new(:pin => 27, :direction => :in, pull: :down)
  #   output_pin = PiPiper::Pin.new(:pin => 17, :direction => :out)

  #   4.times.each do
  #     output_pin.off
  #     puts "Output pin off.  Input = #{input_pin.read}"

  #     output_pin.on
  #     puts "Output pin on.  Input = #{input_pin.read}"
  #   end   
  # end

  # def watch
  #   pin = PiPiper::Pin.new(:pin => PINS_COL[0], :direction => :out)
  #   pin.on

  #   PiPiper.watch :pin => PINS_ROW[0], pull: :up do |pin|
  #     puts "Pin changed from #{pin.last_value} to #{pin.value}"
  #     puts "BUTTON #{BUTTONS[PINS_ROW[0]][PINS_COL[0]]} has value #{pin.value}"
  #   end

  #   PiPiper.wait
  # end
end