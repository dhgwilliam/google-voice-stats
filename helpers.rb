helpers do
  def person_by(person = nil, time_period = "month")
    messages = []
    unless person.nil?
      Message.find(:sent_by_id => person.id).union(:sent_to_id => person.id).each {|message| messages << message}
    else
      Message.all.each {|message| messages << message}
    end
    messages.sort_by! {|message| message.date}

    data = {}
    if time_period == "month"
      increment, limit = "%m", 12
    elsif time_period == "week"
      increment, limit = "%U", 52
    end
    puts limit
    earliest = [ DateTime.parse(messages.first.date).strftime("%Y").to_i, DateTime.parse(messages.first.date).strftime(increment).to_i ]
    counter = earliest
    latest = [ DateTime.now.strftime("%Y").to_i, DateTime.now.strftime(increment).to_i ]
    
    until counter[0] == latest[0] and counter[1] == latest[1]
      data["#{counter[0]}-#{counter[1].to_s.rjust(2, "0")}"] = 0
      puts data
      if counter[1] < limit and counter[0] < latest[0]
        counter[1] += 1
      elsif counter[1] == limit and counter[0] < latest[0]
        counter[1] = 1
        counter[0] += 1
      elsif counter[0] == latest[0] and counter[1] < latest[1]
        counter[1] += 1
      else
        exit
      end
    end

    messages.each do |message|
      if time_period == "month"
        date = DateTime.parse(message.date).strftime("%Y-%m")
      elsif time_period == "week"
        date = DateTime.parse(message.date).strftime("%Y-%U")
      end
      data[date] = data[date].to_i + 1
    end
    [data, time_period]
  end
end

