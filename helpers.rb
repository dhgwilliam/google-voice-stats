require 'nilsimsa'
require 'pandoc-ruby'

helpers do
  $all_c = []

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

  def parse(person)
    puts "Start #{Time.now}"
    s = Dir.new(File.join('.', 'data'))
    files = []
    s.each {|file|  if file.include? person and !file.include? ".mp3" and !File.directory?(File.join('.', 'data', file)) then files << file end }
    s.close
    files.each do |file|
      o_file = File.open(File.join('.', 'data', file)).readlines.join
      title = o_file.match(/\<title\>(.*?)<\/title\>/x)
      puts title
      doc = PandocRuby.new(o_file, :from => :html, :to => :markdown).convert

      lines = []
      doc.split(/\n/).each {|line| lines << line }

      fixed = []
      if lines then lines.reject! {|x| x.match(/^(Labels.*|\[Text.*)/)} end

      begin
        lines.each do |line|
          unless line.match(/^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)/)
            fixed << fixed.pop.chomp + " " + line
          else
            fixed << line
          end
        end
      rescue NoMethodError
      end

      to_who = "No one"

      fixed.each do |message|
        h = {}
        date = message.match(/^[a-zA-Z]{3} .* Time/)
        who = message.match(/(\[.*?\]|\[Me\])/)
        content = message.match(/(?:\): ).*$/)

        if date && who && content then
          h["date"] = DateTime.parse(date[0])
          h["from"] = who[0].slice(1..-2)
          unless Person.with(:name, h["from"]) then Person.create(:name => h["from"]) end
          h["content"] = content[0].slice(3..-1)
          if h["from"] != "Me" then h["to"] = "Me"; to_who = h["from"] end
          h["to"] ||= nil
          unless h["to"] == nil or h["to"] == "No one"
            unless Person.with(:name, h["to"]) then Person.create(:name => h["to"]) end
          end
          $all_c << h
        end
      end
      $all_c.each {|h| if h["to"].nil? || h["to"] == "No one" then h["to"] = to_who end }
      hasher = Nilsimsa::new
      $all_c.uniq.each do |m|
        prehash = "#{m["date"]}#{m["from"]}#{m["content"]}"
        hasher.update(prehash)
        posthash = hasher.hexdigest
        unless Message.with(:hash, posthash)
          Message.create(:date => m["date"], :content => m["content"], :sent_by => Person.with(:name, m["from"]), :sent_to => Person.with(:name, m["to"]), :hash => posthash)
        end
      end
    end
    puts "End:  #{Time.now}"
  end
end

