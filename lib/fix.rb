#!/usr/bin/env ruby
require 'time'
require 'optparse'
require 'pandoc-ruby'

$options = {}
optparse = OptionParser.new do |opts|
  $options[:name] = nil
  opts.on( '-n', '--name NAME', 'Supply a name to search on' ) do |name|
    $options[:name] = name
  end
  $options[:output] = IO.new STDOUT.fileno
  opts.on( '-o', '--output FILE', 'Export manuscript to a file' ) do |file|
    $options[:output] = File.new(File.join('.', file), 'w')
  end
  $options[:list] = false
  opts.on( '-l', '--list', 'List all available names' ) do
    $options[:list] = true
  end
  $options[:stats] = false
  opts.on( '-s', '--stats', 'Display some dumb stats') do
    $options[:stats] = true
  end
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end
optparse.parse!

if $options[:list]
  names = {}
  s = Dir.new(File.join('.','data'))
  s.each do |filename|
    if filename.include? ".html"
      person = filename.split("-").first.slice(0..-2)
      #unless names.include?(person) then names << person end
      if names[person].nil?
        names[person] = 1
      else
        names[person] = names[person] + 1
      end
    end
  end
  names.each {|name, count| puts "#{count.to_s.rjust(4)} #{name}"}
  exit
end

if $options[:name].nil? and !$options[:list] then puts optparse; exit end

$all_c = []

def parse
  s = Dir.new(File.join('.', 'data'))
  s.each do |file|
    d_name = File.join('.', 'data', file)
    if file.include? $options[:name] and !file.include? ".mp3" and !File.directory?(d_name)
      d = File.open(d_name)
      doc = PandocRuby.new(d.readlines, :from => :html, :to => :markdown).convert
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
          h["content"] = content[0].slice(3..-1)
          if h["from"] != "Me" then h["to"] = "Me"; to_who = h["from"] end
          h["to"] ||= nil
          $all_c << h
        end
      end
      $all_c.each {|h| if h["to"].nil? || h["to"] == "No one" then h["to"] = to_who end }
    end
  end
end

def output(io_stream)
  $all_c.sort_by! {|o| o["date"]}
  $all_c.each_with_index do |o, index|
    if index > 0
      last_time = $all_c[index-1]["date"]
      if last_time.day != o["date"].day then io_stream.puts; io_stream.puts; io_stream.puts "## " + o["date"].strftime("%b %d, %Y") end
      if last_time.hour != o["date"].hour then io_stream.puts; io_stream.puts "*#{o["date"].strftime("%I:%M %P")}*  " end
    else
      io_stream.puts "## " + o["date"].strftime("%b %d, %Y")
      io_stream.puts; io_stream.puts "*#{o["date"].strftime("%I:%M %P")}*  "
    end
    io_stream.puts "**#{o["from"]}**: #{o["content"].gsub(/\\\$/,"$")}  "
  end
end


parse
if $options[:stats]
  who = {}
  $all_c.each {|m| if who[m["from"]].nil? then who[m["from"]] = 1 else who[m["from"]] = who[m["from"]]+1 end}
  who.each do |name, count|
    puts "#{(name+":").ljust(20)} #{count}"
  end
  puts "#{"Total:".ljust(20)} #{$all_c.count}"
else
  output($options[:output])
end
