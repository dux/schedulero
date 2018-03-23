class Schedulero
  module Utils
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

    def quick_overview lines: 200
      data = ['Tasks:']

      for name, task in tasks
        at = task[:at] ? "at #{task[:at]}" : "every #{humanize_seconds(task[:interval])}"

        data.push '- %s, %s' % [name, at]
      end

      data.push ['','###', '']

      data.push `tail -#{lines} #{@log_file}`.split($/).reverse if @log_file

      data.join($/)
    end
  end
end