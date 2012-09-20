require 'sinatra'
require 'time'
require 'ohm'
require 'gchart'

get '/' do
  haml :index
end

get '/people' do
  @people = []
  Person.all.each do |person|
    @people << person
  end
  @people.sort_by! {|person| -Message.find(:sent_to_id => person.id).union(:sent_by_id => person.id).count}
  haml :people
end

get '/person/:person' do
  @messages = []
  Message.find(:sent_by_id => params[:person]).union(:sent_to_id => params[:person]).each do |message|
    @messages << message
  end
  @messages.sort_by! {|message| message.date}
  haml :person
end

get '/monthly' do
  @segments = person_by(nil, "month")
  @time_period = @segments[1]
  @segments = @segments[0]
  @gchart = Gchart.line(:data => @segments.values, :size => "460x200", :axis_with_labels => 'y')
  haml :month
end

get '/monthly/:person' do
  @segments = person_by(Person[params[:person]], "month")
  @time_period = @segments[1]
  @segments = @segments[0]
  @gchart = Gchart.line(:data => @segments.values, :size => "460x200", :axis_with_labels => 'y')
  haml :month
end

get '/weekly' do
  @segments = person_by(nil, "week")
  @time_period = @segments[1]
  @segments = @segments[0]
  @gchart = Gchart.line(:data => @segments.values, :size => "460x200", :axis_with_labels => 'y')
  haml :month
end

get '/weekly/:person' do
  @segments = person_by(Person[params[:person]], "week")
  @time_period = @segments[1]
  @segments = @segments[0]
  @gchart = Gchart.line(:data => @segments.values, :size => "460x200", :axis_with_labels => 'y')
  haml :month
end

get '/debug' do
  haml :debug
end
