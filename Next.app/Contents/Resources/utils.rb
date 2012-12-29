module Utils

    def humanize(timestamp)
        if timestamp > 10368000
            "#{(timestamp / 5184000).to_i} months"
        elsif timestamp > 172800
            "#{(timestamp / 86400).to_i} days"
        else
            hours = (timestamp / 3600).to_i
            min = (timestamp.divmod(3600)[1] / 60).to_i
            min = '0' + min.to_s if min < 10

            "#{hours}:#{min}"
        end
    end

end