require 'pathname'

# pluggable state
# set and get via hash interface
# once init, write at the end of every loop
class Schedulero
  class State
    attr_accessor :state

    def initialize state_file=nil
      state_file ||= "./tmp/schedulero.json"

      @state_file = Pathname.new state_file
      @state_file.write '{}' unless @state_file.exist?
      @state = JSON.load @state_file.read
    end

    def [] name
      @state[name]
    end

    def []= name, value
      @state[name] = value
    end

    def write
      @state_file.write state.to_json
    end
  end
end
