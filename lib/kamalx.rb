# frozen_string_literal: true

require 'eventmachine'
require 'curses'

# Displays a progress bar for a given set of stages.
class ProgressBar
  # All stages Kamal goes through.
  STAGES = [
    'Log into image registry',
    'Build and push app image',
    'Acquiring the deploy lock',
    'Ensure Traefik is running',
    'Detect stale containers',
    'Start container',
    'Prune old containers and images',
    'Releasing the deploy lock',
    'Finished all'
  ].freeze

  # Initializes the progress bar with the given window.
  #
  # @param window [Curses::Window]
  def initialize(window)
    @window = window
    @progress = 0
    @total_steps = STAGES.size
    @blink_state = true
  end

  # Updates the progress bar with the given line.
  #
  # @param line [String]
  def update(line)
    STAGES.each_with_index do |stage, index|
      next unless line.include?(stage)

      @progress = index + 1
      draw
      break
    end
  end

  # Draws the progress bar based on the current progress.
  def draw
    @window.clear
    width = @window.maxx - 2
    progress_width = [(width * (@progress.to_f / @total_steps)).to_i, 1].max

    # Draw progress bar
    @window.setpos(0, 0)
    @window.attron(Curses.color_pair(6)) do # Use green color
      progress_bar = '=' * (progress_width - 1)
      cursor = @blink_state ? '>' : ' '
      progress_bar += @progress == @total_steps ? '>' : cursor
      @window.addstr("[#{progress_bar}#{' ' * [width - progress_width, 0].max}]")
    end

    # Draw stage information
    stage_info = "Current Stage: #{STAGES[@progress - 1]}"
    @window.setpos(1, (width - stage_info.length) / 2)
    @window.attron(Curses::A_BOLD)
    @window.addstr('Current Stage:')
    @window.attroff(Curses::A_BOLD)
    @window.addstr(" #{STAGES[@progress - 1]}")

    @window.refresh
    @blink_state = !@blink_state
  end

  # Finishes the progress bar by setting it to the last stage.
  def finish
    @progress = @total_steps
    draw
  end
end

# Parse lines of log output and extract relevant information from them.
class LogParser
  def initialize
    @hostnames = {}
  end

  def parse(line)
    case line
    when /^(\w+.+)\.{3}$/
      [:white, [:bold, 'Stage:'], " #{::Regexp.last_match(1)}"]
    when /INFO \[(\w+)\] Running (.+) on (.+)/
      command_id = ::Regexp.last_match(1)
      hostname = ::Regexp.last_match(3)
      @hostnames[command_id] = hostname
      [:green, [:bold, "Command[#{command_id}@#{hostname}]"], " #{::Regexp.last_match(2)}"]
    when /INFO \[(\w+)\] Finished in ([\d.]+) seconds with exit status (\d+)/
      command_id = ::Regexp.last_match(1)
      hostname = @hostnames[command_id] || @hostnames.values.first || 'localhost'
      status_color = ::Regexp.last_match(3).to_i == 0 ? :green : :red
      [:yellow, [:bold, "Command[#{command_id}@#{hostname}]"], ' Returned Status: ', status_color,
       ::Regexp.last_match(3)]
    when /DEBUG \[(\w+)\] (.+)/
      [:yellow, [:bold, "Command[#{::Regexp.last_match(1)}@localhost]"], " #{::Regexp.last_match(2)}"]
    when /INFO (.+)/
      [:blue, [:bold, 'Info:'], " #{::Regexp.last_match(1)}"]
    else
      [:white, line]
    end
  end
end

# Provides the entry point for the command-line utility.
#
# @example
#   KamalX.run(ARGV)
#
# @api public
module KamalX
  class ConnectionHandler < EventMachine::Connection
    def initialize(progress_bar)
      super()
      @progress_bar = progress_bar
    end

    def receive_data(data)
      parser = LogParser.new
      data.each_line do |line|
        parsed_line = parser.parse(line)
        KamalX.display_line(parsed_line)
        @progress_bar.update(line)
      end
    end

    def unbind
      @progress_bar.finish
      KamalX.command_finished
    end
  end

  def self.run(args)
    loop do
      setup_curses
      setup_signal_trap
      @command_finished = false
      EventMachine.run do
        command = ['kamal', *args].join(' ')
        @connection_handler = EventMachine.popen(command, ConnectionHandler, @@progress_bar)

        # Add a timer to blink the cursor
        EventMachine.add_periodic_timer(0.5) do
          @@progress_bar.draw unless @command_finished
        end
      end
    end
  end

  def self.command_finished
    @command_finished = true
    @@progress_bar.finish
    @progress_window.refresh
    display_line([:red, [:bold, "Kamal finished. Press 'ctrl+c' to exit."]])
    EventMachine.run {} # Keep the event loop running
  end

  def self.refresh_display
    @stage_window.refresh
    @output_window.refresh
    @output_box.refresh
    @progress_window.refresh
  end

  def self.setup_signal_trap
    Signal.trap('INT') do
      Thread.new do
        sleep 2
        exit!(1)
      end

      EventMachine.stop
      exit(0)
    end
  end

  def self.setup_curses
    Curses.init_screen
    Curses.start_color
    Curses.use_default_colors
    Curses.cbreak
    Curses.noecho
    Curses.stdscr.keypad(true)
    Curses.timeout = 0 # Non-blocking getch

    # Initialize color pairs
    Curses.init_pair(Curses::COLOR_BLUE, Curses::COLOR_BLUE, -1)
    Curses.init_pair(Curses::COLOR_GREEN, Curses::COLOR_GREEN, -1)
    Curses.init_pair(Curses::COLOR_YELLOW, Curses::COLOR_YELLOW, -1)
    Curses.init_pair(Curses::COLOR_RED, Curses::COLOR_RED, -1)
    Curses.init_pair(Curses::COLOR_WHITE, Curses::COLOR_WHITE, -1)
    Curses.init_pair(6, Curses::COLOR_GREEN, -1) # New color pair for green progress bar

    total_lines = Curses.lines
    progress_height = 4
    space_height = 1
    empty_line_height = 1
    remaining_height = total_lines - progress_height - space_height - empty_line_height

    # Create a boxed window for the progress bar
    progress_box = Curses::Window.new(progress_height, Curses.cols, 0, 0)
    progress_box.box('|', '-')
    progress_box.setpos(0, 2)
    progress_box.addstr(' Progress ')
    progress_box.refresh
    @progress_window = progress_box.subwin(2, Curses.cols - 2, 1, 1)

    # Calculate equal heights for stages and output
    section_height = remaining_height / 2

    # Create a boxed window for the stages
    stages_start = progress_height + space_height
    stage_box = Curses::Window.new(section_height, Curses.cols, stages_start, 0)
    stage_box.box('|', '-')
    stage_box.setpos(0, 2)
    stage_box.addstr(' Stage History ')
    stage_box.refresh
    @stage_window = stage_box.subwin(section_height - 2, Curses.cols - 2, stages_start + 1, 1)

    # Create a boxed window for the output area
    output_start = stages_start + section_height + empty_line_height
    @output_box = Curses::Window.new(section_height, Curses.cols, output_start, 0)
    @output_box.box('|', '-')
    @output_box.setpos(0, 2)
    @output_box.addstr(' Command Outputs ')
    @output_box.refresh

    # Create a subwindow inside the box for scrollable content
    @output_window = @output_box.subwin(section_height - 2, Curses.cols - 2, output_start + 1, 1)

    @stage_window.scrollok(true)
    @output_window.scrollok(true)

    @@progress_bar = ProgressBar.new(@progress_window)
  end

  def self.color_map
    @color_map ||= {
      blue: Curses::COLOR_BLUE,
      green: Curses::COLOR_GREEN,
      yellow: Curses::COLOR_YELLOW,
      red: Curses::COLOR_RED,
      white: Curses::COLOR_WHITE
    }
  end

  # @private
  #
  # @api private
  def receive_data(data)
    parser = LogParser.new
    data.each_line do |line|
      parsed_line = parser.parse(line)
      KamalX.display_line(parsed_line)
      @progress_bar.update(line)
    end
  end

  def self.display_stage(parsed_line)
    @stage_window.scroll
    @stage_window.setpos(@stage_window.maxy - 1, 0)

    current_color = nil

    parsed_line.each do |element|
      if element.is_a?(Symbol)
        current_color = color_map[element]
        @stage_window.attron(Curses.color_pair(current_color)) if current_color
      elsif element.is_a?(Array) && element[0] == :bold
        @stage_window.attron(Curses::A_BOLD)
        @stage_window.addstr(element[1].to_s)
        @stage_window.attroff(Curses::A_BOLD)
      else
        @stage_window.addstr(element.to_s)
      end
    end

    @stage_window.attroff(Curses.color_pair(current_color)) if current_color
    @stage_window.refresh
  end

  def self.display_line(parsed_line)
    # Check if the line is a stage command
    if parsed_line.any? { |element| element.is_a?(Array) && element[1] == 'Stage:' }
      display_stage(parsed_line)
    else
      @output_window.scroll
      @output_window.setpos(@output_window.maxy - 1, 0)

      current_color = nil

      parsed_line.each do |element|
        if element.is_a?(Symbol)
          current_color = color_map[element]
        elsif element.is_a?(Array)
          if element[0] == :bold
            @output_window.attron(Curses::A_BOLD) do
              @output_window.attron(Curses.color_pair(current_color)) if current_color
              @output_window.addstr(element[1].to_s)
              @output_window.attroff(Curses.color_pair(current_color)) if current_color
            end
          else
            @output_window.addstr(element[1].to_s)
          end
        else
          @output_window.attron(Curses.color_pair(current_color)) if current_color
          @output_window.addstr(element.to_s)
          @output_window.attroff(Curses.color_pair(current_color)) if current_color
        end
      end

      @output_window.refresh
      @output_box.refresh
    end
  end
end
