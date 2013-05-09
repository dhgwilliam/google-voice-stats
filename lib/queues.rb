$:.unshift('../models')
require 'ohm'
require 'person'

Ohm.connect(:db => "15")

class Sipper
  @queue = "semantic_analysis"

  def self.perform(word, person_id)
    @sample = "dic_#{person_id}"
    a, b, c, d = Ohm.redis.zscore("dic_all", word), Ohm.redis.zscore(@sample, word), 0, 0
    Ohm.redis.zrevrange("dic_all", 0, -1, :withscores => true).each {|pair| c = c + pair.last}
    Ohm.redis.zrevrange(@sample, 0, -1, :withscores => true).each {|pair| d = d + pair.last}
    ll = 2 * ((a*Math.log(a/((c*(a+b))/(c+d))))+(b*Math.log(b/(d*(a+b)/(c+d)))))
    Ohm.redis.zadd("ll_#{person_id}", ll, word)
  end
end

class WhoSipper
  @queue = "semantic_analysis"

  def self.sips_for(person_id)
    @pre_dictionary = Ohm.redis.zrevrange("ll_#{person_id}", 0, -1, :withscores => true)
    scores = []
    @pre_dictionary.each {|pair| scores << pair[1]}
    scores.sort!
    median = scores[(scores.count/2).floor]
    q2 = scores[3*(scores.count/4).floor]
    q1 = scores[(scores.count/4).floor]
    iqr = q2-q1
    Ohm.redis.zrevrangebyscore("ll_#{person_id}", "+inf", median + iqr*3)
  end

  def self.messages_that_include(person_id, word)
    @messages = []
    Message.find(:sent_to_id => person_id).union(:sent_by_id => person_id).each do |message|
      if message.content.downcase.include? word.downcase then @messages << message end
    end
    return @messages
  end

  def self.perform(word)
    @people = []
    Person.all.each do |person|
      unless person.id == "1"
        if sips_for(person.id).flatten.include? word
          @people << person.id
          frequency = messages_that_include(person.id, word).count
          Ohm.redis.zadd("who_has_#{word}", frequency, person.id)
        end
      end
    end
  end
end


