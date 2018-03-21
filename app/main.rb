require 'sinatra/base'
require_relative '../lib/schedulero'

$s = Schedulero.new state_file: './tmp/s.json', log_file: './tmp/s.log'
$s.run_forever

$s.every 'Frequent job', 5 do |cnt|
  r = (rand() * 10).to_i + 10

  puts "... Sleep task #{r} sec".blue

  1.upto(r) do
    puts "x #{cnt}".blue
    sleep 1
  end
end

$s.every('Not so frequent job', 15) {
  puts '... every 15 seconds'
}

$s.at('At 8 o clock', [8, 20]) {
  puts '... it is 8 o clock'.yellow
}

sleep 10_000

class ScheduleroApp < Sinatra::Base
  get '/' do
    content_type :text

    $s.quick_overview
  end
end

run ScheduleroApp