helpers do
  def slice(person)
    messages = []
    Message.find(:sent_by_id => person.id).union(:sent_to_id => person.id).each {|message| messages << message}
    messages.sort_by! {|message| message.date}

    data = {}
    messages.each do |message|
      date = DateTime.parse(message.date).strftime("%Y-%m")
      data[date] = data[date].to_i + 1
    end
    data
  end
end

