require 'json'

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

  def sips_for(person_id, withscores = true)
    @pre_dictionary = Ohm.redis.zrevrange("ll_#{person_id}", 0, -1, :withscores => true)
    scores = []
    @pre_dictionary.each {|pair| scores << pair[1]}
    scores.sort!
    median = scores[(scores.count/2).floor]
    q2 = scores[3*(scores.count/4).floor]
    q1 = scores[(scores.count/4).floor]
    iqr = q2-q1
    Ohm.redis.zrevrangebyscore("ll_#{person_id}", "+inf", median + iqr*3, :withscores => withscores)
  end

  def messages_that_include(person_id, word)
    @messages = []
    Message.find(:sent_to_id => person_id).union(:sent_by_id => person_id).each do |message|
      if message.content.downcase.include? word.downcase then @messages << message end
    end
    return @messages
  end

  def generate_sip_corpus
    sip_corpus = {}
    Person.all.each do |person|
      unless person.id == "1"
        @dictionary = sips_for(person.id, false)
        @dictionary.each do |word|
          if sip_corpus[word].nil?
            sip_corpus[word] = 1
          else
            sip_corpus[word] = sip_corpus[word] + 1
          end
        end
      end
    end
    sip_corpus.each {|word, score| Ohm.redis.zadd("sip_corpus", score, word)}
  end

  def get_sip_corpus(withscores = true)
    if Ohm.redis.zcard("sip_corpus") == 0 then generate_sip_corpus end
    # puts Ohm.redis.zrevrange("sip_corpus", 0, -1, :withscores => withscores).inspect
    Ohm.redis.zrevrange("sip_corpus", 0, -1, :withscores => withscores)
  end

  def who_has_sip(word, withscores = false)
    if Ohm.redis.zcard("who_has_#{word}") == 0
      Resque.enqueue(WhoSipper, word)
    end
    return Ohm.redis.zrevrange("who_has_#{word}", 0, -1, :withscores => withscores)
  end

  def get_all_whosips
    sips = get_sip_corpus(false)
    sips.each do |sip|
      who_has_sip(sip)
    end
  end

  def graph
    sip_hash = {}
    sips = get_sip_corpus
    sips.each do |word|
      sip_hash[word.join("+")] = who_has_sip(word.first)
    end

    nodes = []
    links = []
    people_a = []

    sip_hash.each do |word, people|
      frequency = word.split("+").last.to_i
      word = word.split("+").first
      if frequency > 1 and people.count > 2
        nodes << word
        people.each do |person|
          if Person[person] then person = Person[person].name end
          unless nodes.include? person 
            nodes << person
            people_a << person
          end
          links << { "source" => nodes.index(word), "target" => nodes.index(person) }
        end
      end
    end

    # puts people_a.inspect
    nodes.collect! { |node| if people_a.include? node then group = 2 else group = 1 end; { "name" => node, "group" => group } }

    json = JSON::generate({ "nodes" => nodes, "links" => links })
    graph_json = File.new(File.join(File.dirname(__FILE__), 'public', 'data', 'graph.json'), 'w')
    File.write(graph_json, json)
  end
end
