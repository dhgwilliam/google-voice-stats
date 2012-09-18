require 'sinatra'
require 'time'
require 'ohm'

get '/people' do
  haml :people
end

get '/people/:person/details' do
  @slice = slice(Person[params[:person]])
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

# get '/load/:person' do
#   parse(params[:person])
#   redirect url("/people")
# end

get '/debug' do
  haml :debug
end
