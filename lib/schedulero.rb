require 'pathname'
require 'json'
require 'logger'
require 'colorize'
require 'as-duration'

class Schedulero
  def initialize state_file: nil, log_file: true

    # log file
    log_file = case log_file
      when String
        log_file
      when true
        './log/schedulero.log'
      when false
        nil
    end

    @logger = Logger.new log_file
    @logger.datetime_format = "%Y-%m-%d %H:%M:%S"

    # state file
    unless state_file
      state_file = 'schedulero.json'
      state_file = Dir.exists?('./tmp') ? "./tmp/#{state_file}" : state_file
    end

    @state_file = Pathname.new state_file

    if @state_file.exist?
      @state = JSON.load @state_file.read
    else
      @state = {}
    end
  end

  def run &block
    @logger.info 'running...'

    instance_exec &block

    @state_file.write @state.to_json
  end

  def every name, seconds, &block
    @state[name] ||= 0

    now   = Time.now.to_i
    diff  = (@state[name] + seconds.to_i) - now

    if diff < 0
      puts 'running "%s"' % name.green

      @state[name] = now

      begin
        @logger.info 'Run: %s' % name
        yield
      rescue
        log_errror name
      end
    else
      puts 'skipping "%s" for %s' % [name, humanize_seconds(diff)]
    end
  end

  def at name, hours, &block
    @state[name] ||= 0

    hour_now = Time.now.hour
    hours    = [hours] unless hours.class == Array

    if hours.include?(hour_now) && (Time.now.to_i - @state[name] > 3700)
      puts 'running "%s"' % name.green

      @state[name] = Time.now.to_i

      begin
        @logger.info 'Run: %s' % name
        yield
      rescue
        log_errror name
      end
    else
      puts 'skipping "%s" at %d, running in %s' % [name, hour_now, hours]
    end
  end

  def log_errror name
    msg  = '%s: %s (%s)' % [name, $!.message, $!.class]
    puts msg.red

    Dir.mkdir('./log') unless Dir.exist?('./log')

    @logger.error(msg)
  end

  def humanize_seconds secs
    return '-' unless secs

    secs = secs.to_i

    [[60, :sec], [60, :min], [24, :h], [356, :days], [1000, :years]].map{ |count, name|
      if secs > 0
        secs, n = secs.divmod(count)
        "#{n.to_i} #{name}"
      end
    }.compact.reverse.slice(0,2).join(' ')
  end
end

