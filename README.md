## Simple scheduler

Runs tasks in intervals

### Example

* state_file: where to keep the state? defaults to ./tmp/schedulero.json
* log_file
  * default: ./log/schedulero.log
  * false: do not log

```
require 'schedulero'

# s = Schedulero.new state_file: ..., log_file: ...
s = Schedulero.new

s.run do
  # every 5 seconds
  every 'Frequent job', 5 do
    puts '5 seconds passed'
  end

  # every day
  every 'Slow job', 1.day do
    puts 'day job ...'
  end

  # at specfic hour of the day
  # will run only once per hour
  # at 'At times', 1 do # at 1AM
  # midnight and 6 PM
  at 'At times', [0, 18] do
    p 'BINGO'
  end
end
```

### Instalation

`gem install schedulero`

Run jobs via cron every minute/hour. Jobs will run if needed.

`1 * * * * bin/bash -l -c 'ruby /users/me/jobs.rb'`


### Other info

* logs standard exceptions and runner info to log