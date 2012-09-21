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
    earliest = [ DateTime.parse(messages.first.date).strftime("%Y").to_i, DateTime.parse(messages.first.date).strftime(increment).to_i ]
    counter = earliest
    latest = [ DateTime.now.strftime("%Y").to_i, DateTime.now.strftime(increment).to_i ]
    
    until counter[0] == latest[0] and counter[1] == latest[1]
      data["#{counter[0]}-#{counter[1].to_s.rjust(2, "0")}"] = 0
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

  def build_dic(person_id = nil, time_period = nil)
    unless person_id.nil? then dictionary = "dic_#{person_id}" else dictionary = "dic_all" end
    unless person_id.nil? then Ohm.redis.zremrangebyrank(dictionary, 0, -1)  end
    messages = {}
    unless person_id.nil?
      Message.find(:sent_by_id => person_id).union(:sent_to_id => person_id).each {|message| messages[message.date] = message.content}
    else
      Message.all.each {|message| messages[message.date] = message.content}
    end
    if time_period
      messages.reject! {|date,content| DateTime.parse(date) < time_period[0] or DateTime.parse(date) > time_period[1] }
    end
    messages.values.each do |message|
      message.split(/\s/).each do |word| 
        word = word.downcase.gsub(/\W/, "")
        unless word == ""
          if Ohm.redis.zscore(dictionary, word)
            Ohm.redis.zincrby(dictionary, "1", word)
          else
            Ohm.redis.zadd(dictionary, "1", word)
          end
        end
      end
    end
  end

end
