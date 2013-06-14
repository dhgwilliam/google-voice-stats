require 'ohm'
require 'pandoc-ruby'
require 'time'
require 'digest/md5'

class ConnectionWrapper
  def initialize
    @connection ||= Ohm.connect :db => "15"
  end
end

class DataDir
  attr_reader :path, :files
  def initialize(args)
    @path = File.expand_path(args[:path])
    @files = filenames
  end

  def filenames
    filenames = Array.new
    folder.each {|file|
      filenames << file }
    filenames
  end

  def folder
    @folder ||= Dir.new path
  end

  def filter!
    @files.reject! { |name|
      name.match(/^._/) ||
      !name.end_with?(".html") }
  end

  def absolute_filenames
    @files.map { |filename|
      File.join(@path, filename) }
  end
end

class Conversation
  attr_reader :filename, :contact, :pre_body, :post_body, :messages

  def initialize(args)
    @filename = args[:filename]
    @pre_body = read
    @contact = contact
    @post_body = post_body
    @messages = normalize
  end

  def read
    File.open(@filename).read.encode!('UTF-8', 'UTF-8', :invalid => :replace)
  end

  def contact
    @pre_body.match(/\<title\>(?<title>.*?)<\/title\>/xm)["title"].split("\n").last
  end

  def post_body
    PandocRuby.new(@pre_body, :from => :html, :to => :markdown).convert
  end

  def normalize
    filtered = @post_body.split(/\n/).reject {|line| line.start_with?("Labels", "[Text]")}
    date = /^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]+/
    messages = Array.new
    filtered.each_index { |index|
      line = filtered[index].chomp
      if line.match(date) or messages.empty?
        messages << line
      else
        messages.push(messages.pop.concat(" #{line}"))
      end }
    messages
  end

  def parse!
    @messages.map! { |message|
      TextMessage.new :raw => message, :contact => @contact }
  end

  def save!
    @messages.each { |message|
      message.save! }
  end
end

class TextMessage
  attr_reader :raw, :contact, :timestamp, :sender, :recipient, :body, :hash

  def initialize(args)
    @raw = args[:raw] || ""
    @contact = args[:contact]
    @timestamp = timestamp
    @sender = sender
    @recipient = recipient
    @body = body
    @hash = hash
  end

  def timestamp
    matches = @raw.match(/^[a-zA-Z]{3} .* Time/)
    DateTime.parse(matches[0]) if matches
  end

  def sender
    matches = @raw.match(/(?<=\[)[a-zA-Z0-9' ]+(?=\])/)
    matches[0] if matches
  end

  def recipient
    return @contact if @sender == "Me"
    return "Me" if @sender != "Me"
  end

  def body
    matches = @raw.match(/(?<=\): ).*$/)
    matches[0] if matches
  end

  def hash
    Digest::MD5.hexdigest(@raw)
  end

  def save!
    if @sender && @recipient
      sender    = Person.with(:name, @sender) || Person.create(:name => @sender)
      recipient = Person.with(:name, @recipient) || Person.create(:name => @recipient)
      begin
        Message.create(:contact => @contact,
                       :date    => @timestamp,
                       :sent_by => sender,
                       :sent_to => recipient,
                       :content => @body,
                       :hash    => @hash )
      rescue Ohm::UniqueIndexViolation
      end
    else
      puts @raw
    end
  end
end

class Person < Ohm::Model
  attribute :name

  index :name
  unique :name

  def self.all_people
    @all = Array.new
    Person.all.each {|person| @all << person}
    @all.reject { |person| person.name == "Audio" }
  end
end

class Message < Ohm::Model
  attribute :contact
  attribute :date
  attribute :content
  attribute :hash

  unique :hash

  reference :sent_by, :Person
  reference :sent_to, :Person

  index :sent_by
  index :sent_to

  def validate
    assert_present :sent_by
    assert_present :sent_to
    assert_present :content
    assert_present :date
    assert_present :hash
  end

  def self.with(args)
    contact = args[:contact]

    messages = []
    Message.find(:sent_by_id => contact).union(:sent_to_id => contact).each {|m| messages << m}
    messages.sort_by {|m| m.date}
  end
end
