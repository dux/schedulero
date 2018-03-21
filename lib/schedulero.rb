require 'pathname'
require 'json'
require 'logger'
require 'colorize'
require 'as-duration'
require 'pp'

require_relative './utils'

class Schedulero
  include Schedulero::Utils

  attr_reader :tasks, :logger

  def initialize state_file: nil, log_file: true
    init_log   log_file
    init_state state_file

    @tasks   = {}
    @running = {}
    @count   = 0
  end

  def init_state state_file
    # state file
    state_file ||= "./tmp/schedulero.json"
    puts 'State file: %s' % state_file

    @state_file = Pathname.new state_file
    @state_file.write '{}' unless @state_file.exist?
  end

  def init_log log_file
    # log file
    log_file = case log_file
      when String
        log_file
      when false
        nil
      else
        "./log/schedulero.log'"
    end

    puts 'Log file  : %s' % log_file

    @logger = Logger.new log_file
    @logger.formatter = proc do |severity, datetime, progname, msg|
      severity = severity == 'INFO' ? '' : "(#{severity}) "
      "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}]: #{severity}#{msg}\n"
    end
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
    Thread.new do
      loop do
        puts 'looping ...'
        run
        sleep interval
      end
    end
  end

  # run all tasks once, safe
  def run
    state = JSON.load @state_file.read

    state['_pid']      ||= Process.pid
    state['_last_run'] ||= Time.now.to_i
    diff = Time.now.to_i - state['_last_run']

    # if another process is controlling state, exit
    if state['_pid'] != Process.pid && diff < 10
      puts "Another process [#{state['_pid']}] is controlling state before #{diff} sec, skipping. I am (#{Process.pid})".red
      return
    end

    for name, block in @tasks
      state[name] ||= 0
      now           = Time.now.to_i

      if block[:at]
        # run at specific times
        hour_now = Time.now.hour
        hours    = block[:at].class == Array ? block[:at] : [block[:at]]

        if hours.include?(hour_now) && (Time.now.to_i - state[name] > 3700)
          state[name] = now
          safe_run block
        end
      else
        # run in intervals
        seconds = block[:interval]
        diff    = (state[name].to_i + seconds.to_i) - now

        if diff < 0
          state[name] = now
          safe_run block
        else
          puts 'skipping "%s" for %s' % [name, humanize_seconds(diff)]
        end
      end
    end

    state['_last_run'] = Time.now.to_i
    state['_pid']      = Process.pid

    @state_file.write state.to_json
  end

  # run in rescue mode, kill if still running
  def safe_run block
    name = block[:name]

    puts 'Running "%s"' % name.green
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

    puts msg.red

    @logger.error(msg)
  end
end

