require 'ohm'

class Person < Ohm::Model
  attribute :name

  index :name
  unique :name
end

class Message < Ohm::Model
  attribute :content
  attribute :date
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
  end
end
