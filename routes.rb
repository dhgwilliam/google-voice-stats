require 'sinatra'
require 'time'
require 'ohm'

get '/people' do
  @people = []
  Person.all.each do |person|
    @people << person
  end
  @people.sort_by! {|person| -Message.find(:sent_to_id => person.id).union(:sent_by_id => person.id).count}
  haml :people
end

get '/people/:person/details' do
  @slice = monthly(Person[params[:person]])
  haml :details
end

get '/people/:person' do
  @messages = []
  Message.find(:sent_by_id => params[:person]).union(:sent_to_id => params[:person]).each do |message|
    @messages << message
  end
  @messages.sort_by! {|message| message.date}
  haml :person
end

get '/debug' do
  haml :debug
end
