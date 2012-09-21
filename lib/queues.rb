require 'Ohm'
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

