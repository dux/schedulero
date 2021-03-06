require 'json'
require 'logger'
require 'colorize'
require 'as-duration'
require 'pp'

require_relative './utils'
require_relative './state'

class Schedulero
  include Schedulero::Utils

  attr_reader :tasks, :logger

  def initialize state_file: nil, log_file: true, silent: false, state: nil
    @silent  = silent
    @tasks   = {}
    @running = {}
    @count   = 0

    init_log   log_file

    @state = state || Schedulero::State.new(state_file)
  end

  def init_log log_file
    # log file
    @log_file = case log_file
      when String
        log_file
      when false
        nil
      else
        "./log/schedulero.log"
    end

    show 'Log file  : %s' % @log_file

    @logger = Logger.new @log_file
    @logger.formatter = proc do |severity, datetime, progname, msg|
      severity = severity == 'INFO' ? '' : "(#{severity}) "
      "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}]: #{severity}#{msg}\n"
    end
  end

  def show text
    return if @silent
    puts 'Schedulero: %s' % text
  end

  # add task
  def every name, seconds, proc=nil, &block
    proc ||= block
    @tasks[name] = { interval: seconds , func: proc, name: name }
  end

  # run task at specific hours
  def at name, hours, proc=nil, &block
    proc ||= block
    @tasks[name] = { at: hours , func: proc, name: name }
  end

  def run_forever interval: 3
    return if @forever_thread && @forever_thread.alive?

    show 'Starting forever thread'

    @forever_thread = Thread.start(interval) do
      loop do
        show 'looping ...'
        run
        sleep interval
      end
    end
  end

  # run all tasks once, safe
  def run

    @state['_pid']      ||= Process.pid
    @state['_last_run'] ||= Time.now.to_i

    diff = Time.now.to_i - @state['_last_run']

    # if another process is controlling state, exit
    if @state['_pid'] != Process.pid && diff < 10
      show "Another process [#{@state['_pid']}] is controlling state before #{diff} sec, skipping. I am (#{Process.pid})".red
      return
    end

    for name, block in @tasks
      @state[name] ||= 0
      now           = Time.now.to_i

      if block[:at]
        # run at specific times
        hour_now = Time.now.hour
        hours    = block[:at].class == Array ? block[:at] : [block[:at]]

        if hours.include?(hour_now) && (Time.now.to_i - @state[name] > 3700)
          @state[name] = now
          safe_run block
        end
      else
        # run in intervals
        seconds = block[:interval]
        diff    = (@state[name].to_i + seconds.to_i) - now

        if diff < 0
          @state[name] = now
          safe_run block
        else
          show 'skipping "%s" for %s' % [name, humanize_seconds(diff)]
        end
      end
    end

    @state['_last_run'] = Time.now.to_i
    @state['_pid']      = Process.pid

    @state.write
  end

  # run in rescue mode, kill if still running
  def safe_run block
    name = block[:name]

    show 'Running "%s"' % name.green
    @logger.info 'Run: %s' % name

    if block[:running]
      log_errror "Task [#{block[:name]}] is still running, killing..."
      Thread.kill(block[:running])
    end

    thread = Thread.start(block) do |b|
      block[:running] = thread

      begin
        @count += 1
        b[:func].call @count
      rescue
        log_errror b[:name]
      end

      b[:running] = false
    end
  end

  # show and log error
  def log_errror name
    msg  = if $!
      '%s: %s (%s)' % [name, $!.message, $!.class]
    else
      name
    end

    show msg.red

    @logger.error(msg)
  end
end

