module ScheduleroUtils

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

  def quick_overview lines: 100
    data = ['Tasks:']

    for name, task in tasks
      data.push '- %s, every %s' % [name, humanize_seconds(task[:interval])]
    end

    data.push ['','###', '']

    data.push `tail -#{lines} ./log/schedulero.log`.split($/).reverse

    data.join($/)
  end

end