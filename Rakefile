#encoding: utf-8
if RUBY_VERSION =~ /1.9/
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
end

$:.unshift('lib', 'models')
require 'person.rb'

desc "import refactor"
task :import do
  ENV['path'] ? path = ENV['path'] : path = './data'

  # open connection to redis
  ConnectionWrapper.new

  data = DataDir.new :path => path
  data.filter!
  data.absolute_filenames.each do |filename|
    conversation = Conversation.new :filename => filename
    conversation.parse!
    conversation.save!
  end
end
