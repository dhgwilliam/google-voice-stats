require 'sinatra'
require 'time'
require 'ohm'
require 'gchart'

get '/' do
  @people = []
  Person.all.each {|person| @people << person}
  @people.sort_by! {|person| -Message.find(:sent_to_id => person.id).union(:sent_by_id => person.id).count}
  haml :index
end

get '/people' do
  response['Cache-Control'] = "public, max-age=" + (60).to_s
  @people = []
  Person.all.each {|person| @people << person}
  @people.sort_by! {|person| -Message.find(:sent_to_id => person.id).union(:sent_by_id => person.id).count}
  haml :people, :layout => false
end

get '/person/:person' do
  response['Cache-Control'] = "public, max-age=" + (60*60*24).to_s
  @messages = []
  Message.find(:sent_by_id => params[:person]).union(:sent_to_id => params[:person]).each do |message|
    @messages << message
  end
  @messages.sort_by! {|message| message.date}

  @segments = person_by(Person[params[:person]], "week")
  @time_period = @segments[1]
  @segments = @segments[0]
  @gchart = Gchart.line(:data => @segments.values, :size => "460x200", :axis_with_labels => 'y')

  haml :person
end

get '/monthly' do
  response['Cache-Control'] = "public, max-age=" + (60*60*24).to_s
  @segments = person_by(nil, "month")
  @time_period = @segments[1]
  @segments = @segments[0]
  @gchart = Gchart.line(:data => @segments.values, :size => "460x200", :axis_with_labels => 'y')
  haml :month
end

get '/monthly/:person' do
  response['Cache-Control'] = "public, max-age=" + (60*60*24).to_s
  @segments = person_by(Person[params[:person]], "month")
  @time_period = @segments[1]
  @segments = @segments[0]
  @gchart = Gchart.line(:data => @segments.values, :size => "460x200", :axis_with_labels => 'y')
  haml :month, :layout => false
end

get '/weekly' do
  response['Cache-Control'] = "public, max-age=" + (60*60*24).to_s
  @segments = person_by(nil, "week")
  @time_period = @segments[1]
  @segments = @segments[0]
  @gchart = Gchart.line(:data => @segments.values, :size => "460x200", :axis_with_labels => 'y')
  haml :month
end

get '/weekly/:person' do
  response['Cache-Control'] = "public, max-age=" + (60*60*24).to_s
  @segments = person_by(Person[params[:person]], "week")
  @time_period = @segments[1]
  @segments = @segments[0]
  @gchart = Gchart.line(:data => @segments.values, :size => "460x200", :axis_with_labels => 'y')
  haml :month
end

get '/dictionary/init' do
  build_dic
  redirect url("/dictionary/all")
end

get '/dictionary/nuke' do
  Ohm.redis.zremrangebyscore("dic_all", 0, -1)
  redirect url("/")
end

get '/dictionary/all' do
  response['Cache-Control'] = "public, max-age=" + (60*60*24).to_s
  @dictionary = Ohm.redis.zrevrange("dic_all", 0, 99, :withscores => true)
  haml :dictionary
end

get '/dictionary/refreshall' do
  Person.all.each {|person| unless person.id == "1" then build_dic(person.id) end}
  redirect("/")
end

get '/dictionary/refreshall/sips' do
  Person.all.each do |person| 
    unless person.id == "1" 
      if Ohm.redis.zcard("ll_#{person.id}") == 0
        Ohm.redis.zadd("ll_#{person.id}", 0, "i")
        list = Ohm.redis.zrevrange("dic_#{person.id}", 0, -1)
        list.each do |word|
          Resque.enqueue(Sipper, word, person.id)
        end
      end
    end
  end
  redirect("/")
end

get '/person/:person_id/dictionary/refresh' do
  build_dic(params[:person_id])
  redirect url("/person/#{params[:person_id]}/dictionary")
end

get '/person/:person_id/dictionary' do
  response['Cache-Control'] = "public, max-age=" + (60*60*24).to_s
  @dictionary = Ohm.redis.zrevrange("dic_#{params[:person_id]}", 0, -1, :withscores => true)
  haml :dictionary
end

get '/person/:person_id/sips' do
  response['Cache-Control'] = "public, max-age=" + (60*60*24).to_s
  if Ohm.redis.zcard("ll_#{params[:person_id]}") == 0
    Ohm.redis.zadd("ll_#{params[:person_id]}", 0, "i")
    list = Ohm.redis.zrevrange("dic_#{params[:person_id]}", 0, -1)
    list.each { |word| Resque.enqueue(Sipper, word, params[:person_id]) }
    @sample = "dic_#{params[:person_id]}"
  end
  @dictionary = sips_for(params[:person_id])
  haml :dictionary
end

get '/keyword/:keyword' do
  response['Cache-Control'] = "public, max-age=" + (60*60*24).to_s
  @messages = []
  Message.all.each do |message|
    if message.content.downcase.include? params[:keyword].downcase then @messages << message end
  end
  haml :keyword
end

get '/keyword/:keyword/with/:person_id' do
  response['Cache-Control'] = "public, max-age=" + (60*60*24).to_s
  @messages = messages_that_include(params[:person_id], params[:keyword])
  haml :keyword
end

get '/sip' do
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
  @dictionary = []
  sip_corpus.each {|word, score| @dictionary << [word, score] }
  @dictionary.reject! {|pair| pair.last < 3}
  @dictionary.inspect
end

get '/sip/:keyword' do
  @people = []
  Person.all.each do |person|
    unless person.id == "1"
      if sips_for(person.id).flatten.include? params[:keyword] then @people << person.id end
    end
  end
  @people.each do |person_id|
    frequency = messages_that_include(person_id, params[:keyword]).count
    distance = 1/frequency.to_f
    puts "#{Person[person_id].name} frequency: #{frequency} distance: #{distance}"
  end
end
